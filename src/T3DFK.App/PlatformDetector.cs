using System.Runtime.InteropServices;

namespace T3DFK;

public enum FieldPlatform { Windows, MacIntel, MacAppleSilicon, Unsupported }

public static class PlatformDetector
{
    public static FieldPlatform Detect()
    {
        if (OperatingSystem.IsWindows()) return FieldPlatform.Windows;
        if (OperatingSystem.IsMacOS())
            return RuntimeInformation.OSArchitecture == Architecture.Arm64 ? FieldPlatform.MacAppleSilicon : FieldPlatform.MacIntel;
        return FieldPlatform.Unsupported;
    }

    public static string Label(FieldPlatform p) => p switch
    {
        FieldPlatform.Windows => "Windows",
        FieldPlatform.MacIntel => "macOS Intel",
        FieldPlatform.MacAppleSilicon => "macOS Apple Silicon",
        _ => "Unsupported platform"
    };
}
