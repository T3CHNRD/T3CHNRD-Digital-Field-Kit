using System.Diagnostics;

namespace T3DFK;

public static class DeploymentService
{
    private static readonly string[] WingetIds =
    {
        "Google.Chrome",
        "Mozilla.Firefox",
        "Malwarebytes.Malwarebytes",
        "AVG.Antivirus.Free",
        "Piriform.CCleaner"
    };

    public static async Task<int> InstallAllWindowsAsync(Action<string> output)
    {
        if (!OperatingSystem.IsWindows()) throw new PlatformNotSupportedException("Deployment Install All is Windows-only.");
        foreach (var id in WingetIds)
        {
            output($"> winget install {id}");
            var p = Process.Start(new ProcessStartInfo("winget.exe", $"install --id {id} --exact --accept-package-agreements --accept-source-agreements")
            {
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            });
            if (p is null) return 1;
            output(await p.StandardOutput.ReadToEndAsync());
            output(await p.StandardError.ReadToEndAsync());
            await p.WaitForExitAsync();
            if (p.ExitCode != 0) return p.ExitCode;
        }
        return 0;
    }
}
