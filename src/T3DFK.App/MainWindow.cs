using Avalonia;
using Avalonia.Controls;
using Avalonia.Layout;
using Avalonia.Media;
using Avalonia.Platform.Storage;

namespace T3DFK;

public sealed class MainWindow : Window
{
    private readonly string _root = AppContext.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar);
    private readonly ToolRunner _runner = new();
    private readonly TextBox _output = new() { IsReadOnly = true, AcceptsReturn = true, TextWrapping = TextWrapping.NoWrap };
    private readonly StackPanel _cards = new() { Spacing = 8 };
    private readonly TextBlock _platform = new();
    private FieldPlatform _selected;

    public MainWindow()
    {
        Title = "T3CHNRD Digital Field Kit";
        Width = 1260;
        Height = 820;
        MinWidth = 900;
        MinHeight = 620;
        _selected = PlatformDetector.Detect();
        _runner.Output += line => Avalonia.Threading.Dispatcher.UIThread.Post(() => Append(line));
        _runner.Completed += code => Avalonia.Threading.Dispatcher.UIThread.Post(() => Append($"Completed with exit code {code}."));
        Content = BuildUi();
        RenderTools();
    }

    private Control BuildUi()
    {
        var root = new DockPanel();
        var header = new Border { Padding = new Thickness(18), Background = new SolidColorBrush(Color.Parse("#0B5C7A")) };
        var headerGrid = new Grid { ColumnDefinitions = new ColumnDefinitions("*,Auto") };
        headerGrid.Children.Add(new StackPanel
        {
            Children =
            {
                new TextBlock { Text = "T3CHNRD Digital Field Kit", FontSize = 27, FontWeight = FontWeight.Bold, Foreground = Brushes.White },
                new TextBlock { Text = "Diagnose  |  Repair  |  Optimize  |  Deploy", Foreground = Brushes.White }
            }
        });
        _platform.Text = "Detected: " + PlatformDetector.Label(_selected);
        _platform.Foreground = Brushes.White;
        _platform.VerticalAlignment = VerticalAlignment.Center;
        Grid.SetColumn(_platform, 1);
        headerGrid.Children.Add(_platform);
        header.Child = headerGrid;
        DockPanel.SetDock(header, Dock.Top);
        root.Children.Add(header);

        var nav = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8, Margin = new Thickness(12) };
        nav.Children.Add(MakeButton("Auto Detect", () => SelectPlatform(PlatformDetector.Detect())));
        nav.Children.Add(MakeButton("Windows", () => SelectPlatform(FieldPlatform.Windows)));
        nav.Children.Add(MakeButton("macOS Intel", () => SelectPlatform(FieldPlatform.MacIntel)));
        nav.Children.Add(MakeButton("macOS Apple Silicon", () => SelectPlatform(FieldPlatform.MacAppleSilicon)));
        nav.Children.Add(MakeButton("Install All Apps", InstallAll));
        nav.Children.Add(MakeButton("Add Runbook Document", ImportRunbook));
        DockPanel.SetDock(nav, Dock.Top);
        root.Children.Add(nav);

        var grid = new Grid { ColumnDefinitions = new ColumnDefinitions("2*,3*"), Margin = new Thickness(12), ColumnSpacing = 12 };
        var scroll = new ScrollViewer { Content = _cards };
        grid.Children.Add(scroll);
        Grid.SetColumn(_output, 1);
        grid.Children.Add(_output);
        root.Children.Add(grid);
        return root;
    }

    private Button MakeButton(string text, Action action)
    {
        var b = new Button { Content = text, Padding = new Thickness(14, 8) };
        b.Click += (_, _) => action();
        return b;
    }

    private void SelectPlatform(FieldPlatform platform)
    {
        _selected = platform;
        _platform.Text = "Selected: " + PlatformDetector.Label(_selected) + " | Actual: " + PlatformDetector.Label(PlatformDetector.Detect());
        RenderTools();
    }

    private void RenderTools()
    {
        _cards.Children.Clear();
        foreach (var tool in ToolCatalog.All.Where(t => t.Platform == _selected))
        {
            var b = new Button { HorizontalContentAlignment = HorizontalAlignment.Stretch, Padding = new Thickness(14) };
            b.Content = new StackPanel
            {
                Children =
                {
                    new TextBlock { Text = tool.Name, FontWeight = FontWeight.Bold, FontSize = 16 },
                    new TextBlock { Text = tool.Category + " - " + tool.Description, TextWrapping = TextWrapping.Wrap }
                }
            };
            b.Click += async (_, _) =>
            {
                Append($"Starting {tool.Name}...");
                try { await _runner.RunAsync(tool, _root); }
                catch (Exception ex) { Append("ERROR: " + ex.Message); }
            };
            _cards.Children.Add(b);
        }
        if (_cards.Children.Count == 0)
            _cards.Children.Add(new TextBlock { Text = "No tools are assigned to this platform yet." });
    }

    private async void InstallAll()
    {
        if (!OperatingSystem.IsWindows()) { Append("Install All Apps is Windows-only."); return; }
        Append("Install All includes Chrome, Firefox, Malwarebytes, AVG, and CCleaner only. Win11Debloat and WinUtil are excluded.");
        try { Append("Install All exit code: " + await DeploymentService.InstallAllWindowsAsync(Append)); }
        catch (Exception ex) { Append("ERROR: " + ex.Message); }
    }

    private async void ImportRunbook()
    {
        var files = await StorageProvider.OpenFilePickerAsync(new FilePickerOpenOptions { Title = "Add document to Runbook", AllowMultiple = true });
        var dest = Path.Combine(_root, "Runbook");
        Directory.CreateDirectory(dest);
        foreach (var file in files)
        {
            var local = file.TryGetLocalPath();
            if (string.IsNullOrWhiteSpace(local)) { Append($"Skipped non-local document: {file.Name}"); continue; }
            var target = Path.Combine(dest, Path.GetFileName(local));
            File.Copy(local, target, overwrite: true);
            Append("Imported: " + Path.GetFileName(local));
        }
    }

    private void Append(string text)
    {
        _output.Text = (_output.Text ?? "") + text + Environment.NewLine;
        _output.CaretIndex = _output.Text?.Length ?? 0;
    }
}
