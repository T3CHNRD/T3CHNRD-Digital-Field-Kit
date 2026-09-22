using System;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;

// Stream readers run in .NET, never PowerShell callbacks on threads without a runspace.
public sealed class RunCenterProcess : IDisposable
{
    public readonly Process Process;
    public readonly ConcurrentQueue<string> Output = new ConcurrentQueue<string>();
    private Task stdout;
    private Task stderr;

    public RunCenterProcess(ProcessStartInfo info) { Process = new Process { StartInfo = info }; }
    public void Start()
    {
        if (!Process.Start()) throw new InvalidOperationException("The tool process did not start.");
        stdout = Pump(Process.StandardOutput, "");
        stderr = Pump(Process.StandardError, "ERROR: ");
    }
    private async Task Pump(StreamReader reader, string prefix)
    {
        try
        {
            var buffer = new byte[4096];
            var chars = new char[reader.CurrentEncoding.GetMaxCharCount(buffer.Length)];
            var decoder = reader.CurrentEncoding.GetDecoder();
            int count;
            while ((count = await reader.BaseStream.ReadAsync(buffer, 0, buffer.Length).ConfigureAwait(false)) != 0)
            {
                int charCount = decoder.GetChars(buffer, 0, count, chars, 0, false);
                Output.Enqueue(prefix + new string(chars, 0, charCount));
            }
            int finalCount = decoder.GetChars(buffer, 0, 0, chars, 0, true);
            if (finalCount > 0) Output.Enqueue(prefix + new string(chars, 0, finalCount));
        }
        catch (Exception error) { Output.Enqueue("Stream error: " + error.Message + Environment.NewLine); }
    }
    public bool Finished { get { return Process.HasExited && stdout.IsCompleted && stderr.IsCompleted; } }
    public void Dispose() { Process.Dispose(); }
}
