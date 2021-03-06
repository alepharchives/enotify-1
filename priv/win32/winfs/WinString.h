#ifndef _ENotify_WinString
#define _ENotify_WinString

#include <windows.h>
#include <winbase.h>
#include <winnt.h>
#include <string>

using namespace std;

wstring UTF8BinToUtf16Str(const char* bin, int binLength);
string UTF16toUTF8(const WCHAR* utf16);
void UTF16toUTF8_inBuffer(const WCHAR* utf16, char* utf8, int len);

#endif
