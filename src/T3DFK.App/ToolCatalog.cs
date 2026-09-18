namespace T3DFK;

public static class ToolCatalog
{
    public static IReadOnlyList<ToolDefinition> All { get; } = new List<ToolDefinition>
    {
        new("win-system-info","System Information","Diagnostics","Collect Windows hardware and OS information.",FieldPlatform.Windows,"powershell.exe","-NoProfile -ExecutionPolicy Bypass -File \"{ROOT}\\scripts\\windows\\System-Info.ps1\""),
        new("win-network","Network Summary","Network","Collect adapters, routes and DNS configuration.",FieldPlatform.Windows,"powershell.exe","-NoProfile -ExecutionPolicy Bypass -File \"{ROOT}\\scripts\\windows\\Network-Summary.ps1\""),
        new("win-disk","Disk Summary","Storage","Collect disk and free-space information.",FieldPlatform.Windows,"powershell.exe","-NoProfile -ExecutionPolicy Bypass -File \"{ROOT}\\scripts\\windows\\Disk-Summary.ps1\""),
        new("mac-system-info","System Information","Diagnostics","Collect macOS hardware and OS information.",FieldPlatform.MacIntel,"/bin/zsh","\"{ROOT}/scripts/macos/system-info.sh\""),
        new("mac-system-info-arm","System Information","Diagnostics","Collect macOS hardware and OS information.",FieldPlatform.MacAppleSilicon,"/bin/zsh","\"{ROOT}/scripts/macos/system-info.sh\"")
    };
}
