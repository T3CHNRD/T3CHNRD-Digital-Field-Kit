using System.Text.Json;

namespace T3DFK;

internal static class Program
{
    [STAThread]
    static int Main(string[] args)
    {
        try
        {
            var paths = AppPaths.Detect();
            if (args.Contains("--self-test", StringComparer.OrdinalIgnoreCase)) return SelfTest(paths);
            if (args.Contains("--runner-self-test", StringComparer.OrdinalIgnoreCase)) return RunnerSelfTest(paths).GetAwaiter().GetResult();
            var tools = LoadTools(paths);
            ApplicationConfiguration.Initialize();
            Application.Run(new MainForm(paths, tools));
            return 0;
        }
        catch (Exception ex)
        {
            try { MessageBox.Show(ex.ToString(), "T3CHNRD Digital Field Kit - Startup Error", MessageBoxButtons.OK, MessageBoxIcon.Error); } catch { }
            return 1;
        }
    }

    private static List<ToolDefinition> LoadTools(AppPaths paths)
    {
        if (!File.Exists(paths.ToolManifest)) throw new FileNotFoundException("Tool manifest is missing.", paths.ToolManifest);
        var tools = JsonSerializer.Deserialize<List<ToolDefinition>>(File.ReadAllText(paths.ToolManifest), new JsonSerializerOptions { PropertyNameCaseInsensitive = true }) ?? new();
        if (tools.Count == 0) throw new InvalidDataException("Tool manifest contains no tools.");
        return tools;
    }

    private static int SelfTest(AppPaths paths)
    {
        try
        {
            var tools = LoadTools(paths);
            foreach (var t in tools)
            {
                var p = Path.GetFullPath(Path.Combine(paths.Root, t.Path.Replace('\', Path.DirectorySeparatorChar)));
                if (!File.Exists(p)) return 20;
            }
            if (!File.Exists(paths.ScriptHashes)) return 21;
            if (!File.Exists(Path.Combine(paths.AssetsDirectory, "Toolkit.ico"))) return 22;
            return 0;
        }
        catch { return 99; }
    }

    private static async Task<int> RunnerSelfTest(AppPaths paths)
    {
        var tmp = Path.Combine(paths.Root, "Scripts", "Core", "__v11_runner_selftest.ps1");
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(tmp)!);
            File.WriteAllText(tmp, "Write-Output 'T3DFK_RUNNER_OK'; exit 0\r\n");
            var tool = new ToolDefinition { Id = "selftest", Name = "Runner Self Test", Path = Path.GetRelativePath(paths.Root, tmp), Risk = "ReadOnly", Interactive = false };
            var runner = new ToolRunner(paths);
            var saw = false;
            var exit = int.MinValue;
            runner.Output += line => { if (line.Contains("T3DFK_RUNNER_OK", StringComparison.Ordinal)) saw = true; };
            runner.Completed += r => exit = r.ExitCode;
            await runner.RunAsync(tool);
            return saw && exit == 0 ? 0 : 30;
        }
        catch { return 31; }
        finally { try { if (File.Exists(tmp)) File.Delete(tmp); } catch { } }
    }
}
