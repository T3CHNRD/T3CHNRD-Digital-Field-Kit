using System;
using System.Diagnostics;
using System.IO;
using System.Security.Principal;
using System.Windows.Forms;
static class Program {
 [STAThread] static void Main(){
  try{
   string root=AppDomain.CurrentDomain.BaseDirectory;
   string hta=Path.Combine(root,"Toolkit.hta");
   if(!File.Exists(hta)){MessageBox.Show("Toolkit.hta is missing.","T3CHNRD Digital Field Kit",MessageBoxButtons.OK,MessageBoxIcon.Error);return;}
   bool admin=new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator);
   var psi=new ProcessStartInfo("mshta.exe","\""+hta+"\""){UseShellExecute=true,WorkingDirectory=root};
   if(!admin) psi.Verb="runas";
   Process.Start(psi);
  }catch(Exception ex){MessageBox.Show(ex.Message,"T3CHNRD Digital Field Kit",MessageBoxButtons.OK,MessageBoxIcon.Error);}
 }
}
