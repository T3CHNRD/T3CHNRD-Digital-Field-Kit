using System.Diagnostics;
using System.Text;

namespace T3DFK;

public sealed class ToolRunResult
{
    public int ExitCode { get; init; }
    public string LogPath { get; init; } = "";
    public bool Cancelled { get; init; }
}

public sealed class ToolRunner
{
    private readonly AppPaths _paths;
    private Process? _current;
    private StreamWriter? _log;
    private readonly object _sync = new();
    public bool IsRunning => _current is { HasExited: false };
    public event Action<string>? Output;
    public event Action<string>? Error;
    public event Action<int>? Started;
    public event Action<ToolRunResult>? Completed;

    public ToolRunner(AppPaths paths) => _paths = paths;

    public async Task RunAsync(ToolDefinition tool, CancellationToken cancellationToken = default)
    {
        if (IsRunning) throw new InvalidOperationException("Another tool is already running.");
        var script = Path.GetFullPath(Path.Combine(_paths.Root, tool.Path.Replace('\', Path.DirectorySeparatorChar)));
        if (!script.StartsWith(_paths.Root, StringComparison.OrdinalIgnoreCase) || !File.Exists(script))
            throw new FileNotFoundException("Tool script was not found.", script);

        if (tool.Interactive)
        {
            RunInteractive(tool, script);
            return;
        }

        var safeName = string.Concat(tool.Name.Select(ch => Path.GetInvalidFileNameChars().Contains(ch) ? '_' : ch));
        var session = Path.Combine(_paths.ReportsDirectory, "AppLogs");
        Directory.CreateDirectory(session);
        var logPath = Path.Combine(session, $"{DateTime.Now:yyyyMMdd-HHmmss}-{safeName}.log");
        _log = new StreamWriter(logPath, append: false, new UTF8Encoding(false)) { AutoFlush = true };
        _log.WriteLine("T3CHNRD Digital Field Kit v11");
        _log.WriteLine($"Tool: {tool.Name}");
        _log.WriteLine($"Script: {script}");
        _log.WriteLine($"Started: {DateTimeOffset.Now:O}");
        _log.WriteLine(new string('-', 72));

        var ps = ResolvePowerShell();
        var command = BuildCommand(script, tool.Args);
        var encoded = Convert.ToBase64String(Encoding.Unicode.GetBytes(command));
        var psi = new ProcessStartInfo
        {
            FileName = ps,
            Arguments = $"-NoLogo -NoProfile -ExecutionPolicy Bypass -EncodedCommand {encoded}",
            WorkingDirectory = _paths.Root,
            UseShellExecute = false,
            CreateNoWindow = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            RedirectStandardInput = true
        };
        psi.Environment["T3DFK_ROOT"] = _paths.Root;
        psi.Environment["T3DFK_REPORTS"] = _paths.ReportsDirectory;

        var process = new Process { StartInfo = psi, EnableRaisingEvents = true };
        process.OutputDataReceived += (_, e) => { if (e.Data != null) WriteLine(e.Data, false); };
        process.ErrorDataReceived += (_, e) => { if (e.Data != null) WriteLine(e.Data, true); };
        if (!process.Start()) throw new InvalidOperationException("Windows did not start PowerShell.");
        _current = process;
        Started?.Invoke(process.Id);
        process.BeginOutputReadLine();
        process.BeginErrorReadLine();

        using var reg = cancellationToken.Register(Cancel);
        await process.WaitForExitAsync(cancellationToken).ConfigureAwait(false);
        process.WaitForExit();
        var exit = process.ExitCode;
        _log.WriteLine(new string('-', 72));
        _log.WriteLine($"Completed: {DateTimeOffset.Now:O}");
        _log.WriteLine($"ExitCode: {exit}");
        _log.Dispose();
        _log = null;
        _current = null;
        Completed?.Invoke(new ToolRunResult { ExitCode = exit, LogPath = logPath, Cancelled = false });
    }

    public void Cancel()
    {
        lock (_sync)
        {
            try
            {
                if (_current is { HasExited: false })
                {
                    _log?.WriteLine("Cancellation requested by technician.");
                    _current.Kill(entireProcessTree: true);
                }
            }
            catch (Exception ex)
            {
                _log?.WriteLine("Cancellation error: " + ex.Message);
            }
        }
    }

    private void RunInteractive(ToolDefinition tool, string script)
    {
        var ps = ResolvePowerShell();
        var command = BuildCommand(script, tool.Args);
        var encoded = Convert.ToBase64String(Encoding.Unicode.GetBytes(command));
        var psi = new ProcessStartInfo
        {
            FileName = ps,
            Arguments = $"-NoExit -NoLogo -NoProfile -ExecutionPolicy Bypass -EncodedCommand {encoded}",
            WorkingDirectory = _paths.Root,
            UseShellExecute = true
        };
        Process.Start(psi);
    }

    private void WriteLine(string line, bool isError)
    {
        lock (_sync) _log?.WriteLine((isError ? "[ERR] " : "") + line);
        if (isError) Error?.Invoke(line); else Output?.Invoke(line);
    }

    private static string BuildCommand(string script, IEnumerable<string> args)
    {
        static string Quote(string s) => "'" + s.Replace("'", "''") + "'";
        var argText = string.Join(" ", args.Select(Quote));
        return "$ErrorActionPreference='Continue'; & " + Quote(script) + (argText.Length > 0 ? " " + argText : "") + "; if ($null -ne $LASTEXITCODE) { exit $LASTEXITCODE } else { exit 0 }";
    }

    public static string ResolvePowerShell()
    {
        var system = Environment.GetFolderPath(Environment.SpecialFolder.System);
        var ps = Path.Combine(system, "WindowsPowerShell", "v1.0", "powershell.exe");
        return File.Exists(ps) ? ps : "powershell.exe";
    }
}
