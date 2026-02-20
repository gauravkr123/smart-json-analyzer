// JSONDeepDiff.cs — Windows native wrapper using WebView2
// Compile on Windows: create-win-exe.bat
// Requires: .NET 6+ SDK  (winget install Microsoft.DotNet.SDK.8)

using System;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using Microsoft.Web.WebView2.Wpf;

namespace JSONDeepDiff
{
    public class App : Application
    {
        [STAThread]
        public static void Main(string[] args)
        {
            var app = new App();
            var win = new MainWindow(args);
            app.Run(win);
        }
    }

    public class MainWindow : Window
    {
        private readonly WebView2 _webView;
        private string[]? _pendingFiles;

        public MainWindow(string[] args)
        {
            Title = "JSON Diff v4";
            Width = 1400;
            Height = 900;
            WindowStartupLocation = WindowStartupLocation.CenterScreen;

            _webView = new WebView2();
            Content = _webView;

            if (args.Length > 0)
                _pendingFiles = args;

            Loaded += async (_, _) =>
            {
                var env = await Microsoft.Web.WebView2.Core.CoreWebView2Environment.CreateAsync();
                await _webView.EnsureCoreWebView2Async(env);

                // Load embedded HTML from Resources folder next to the exe
                var exeDir = AppDomain.CurrentDomain.BaseDirectory;
                var htmlPath = Path.Combine(exeDir, "Resources", "index.html");
                if (!File.Exists(htmlPath))
                    htmlPath = Path.Combine(exeDir, "index.html");
                if (!File.Exists(htmlPath))
                {
                    MessageBox.Show("index.html not found!", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                    Close();
                    return;
                }

                _webView.CoreWebView2.NavigationCompleted += async (s, e) =>
                {
                    if (_pendingFiles != null && _pendingFiles.Length > 0)
                    {
                        await InjectFiles(_pendingFiles);
                        _pendingFiles = null;
                    }
                };

                _webView.CoreWebView2.Navigate(new Uri(htmlPath).AbsoluteUri);

                // Allow file drag-and-drop onto the window
                AllowDrop = true;
                Drop += async (s, e) =>
                {
                    if (e.Data.GetDataPresent(DataFormats.FileDrop))
                    {
                        var files = (string[])e.Data.GetData(DataFormats.FileDrop)!;
                        var jsonFiles = Array.FindAll(files, f =>
                            f.EndsWith(".json", StringComparison.OrdinalIgnoreCase));
                        if (jsonFiles.Length > 0)
                            await InjectFiles(jsonFiles);
                    }
                };
                DragOver += (s, e) =>
                {
                    e.Effects = DragDropEffects.Copy;
                    e.Handled = true;
                };
            };
        }

        private async System.Threading.Tasks.Task InjectFiles(string[] files)
        {
            string? contentA = null, contentB = null;
            try { contentA = File.ReadAllText(files[0]); } catch { }
            if (files.Length > 1)
                try { contentB = File.ReadAllText(files[1]); } catch { }

            var jsA = contentA != null
                ? System.Text.Json.JsonSerializer.Serialize(contentA)
                : "null";
            var jsB = contentB != null
                ? System.Text.Json.JsonSerializer.Serialize(contentB)
                : "null";

            var script = $@"
                (function() {{
                    var a = document.getElementById('jsonA');
                    var b = document.getElementById('jsonB');
                    if (a && {jsA} !== null) a.value = {jsA};
                    if (b && {jsB} !== null) b.value = {jsB};
                }})();";

            await _webView.CoreWebView2.ExecuteScriptAsync(script);
        }
    }
}
