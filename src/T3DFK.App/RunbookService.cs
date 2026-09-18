namespace T3DFK;

public static class RunbookService
{
    public static readonly string[] ExcludedSegments =
    {
        ".venv312", "ai_cowork", "apps", "deps.txt", "static", "static\\robots.txt", "templates",
        "tmp-lo-test2", "tmp-lo-test2\\AB_Cluster.pdf", "tmp_backend.html", "tmp_backend_v.txt"
    };

    public static bool IsVisible(string path)
    {
        var normalized = path.Replace('/', '\\');
        return !ExcludedSegments.Any(x => normalized.Contains(x, StringComparison.OrdinalIgnoreCase));
    }
}
