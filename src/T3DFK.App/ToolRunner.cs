using System.Diagnostics;

namespace T3DFK;

public sealed class ToolRunner
{
    private Process? _current;
    public event Action<string>? Output;
    public event Action<int>? Completed;
    public bool IsRunning => _current is { HasExited: false };

    public async Task RunAsync(ToolDefinition tool, string root, CancellationToken cancellationToken = default)
    {
        if (IsRunning) throw new InvalidOperationException("A tool is already running.");
        var args = tool.Arguments.Replace("{ROOT}", root, StringComparison.Ordinal);
        var psi = new ProcessStartInfo(tool.Command, args)
        {
            WorkingDirectory = root,
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true
        };
        _current = new Process { StartInfo = psi, EnableRaisingEvents = true };
        _current.OutputDataReceived += (_, e) => { if (e.Data is not null) Output?.Invoke(e.Data); };
        _current.ErrorDataReceived += (_, e) => { if (e.Data is not null) Output?.Invoke("ERROR: " + e.Data); };
        _current.Start();
        _current.BeginOutputReadLine();
        _current.BeginErrorReadLine();
        using var reg = cancellationToken.Register(Cancel);
        await _current.WaitForExitAsync(cancellationToken);
        var code = _current.ExitCode;
        _current.Dispose();
        _current = null;
        Completed?.Invoke(code);
    }

    public void Cancel()
    {
        try { if (_current is { HasExited: false }) _current.Kill(entireProcessTree: true); } catch { }
    }
}
