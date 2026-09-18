namespace T3DFK;

public sealed class AppPaths
{
    public string Root { get; }
    public string ConfigDirectory => Path.Combine(Root, "Config");
    public string ScriptsDirectory => Path.Combine(Root, "Scripts");
    public string AssetsDirectory => Path.Combine(Root, "Assets");
    public string RunbookDirectory => Path.Combine(Root, "Runbook");
    public string ReportsDirectory => Path.Combine(Root, "Diagnostic-Reports");
    public string ToolManifest => Path.Combine(ConfigDirectory, "tools.json");
    public string ScriptHashes => Path.Combine(ConfigDirectory, "scripts.sha256");
    public string SettingsDirectory => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "T3DFK");
    public string FavoritesFile => Path.Combine(SettingsDirectory, "favorites.json");
    public string RecentFile => Path.Combine(SettingsDirectory, "recent.json");

    public AppPaths(string root)
    {
        Root = root;
        Directory.CreateDirectory(ReportsDirectory);
        Directory.CreateDirectory(SettingsDirectory);
        Directory.CreateDirectory(RunbookDirectory);
    }

    public static AppPaths Detect()
    {
        var baseDir = AppContext.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar);
        return new AppPaths(baseDir);
    }
}
