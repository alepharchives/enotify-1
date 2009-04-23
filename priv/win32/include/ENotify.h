#include "erl_comm.h"
extern "C"
{
	#include "erl_interface.h"
	#include "ei.h"
}

extern int eNotify_init(void);
extern int eNotify_addWatch(const char* path, long notifyFilter, bool watchSubdir);
extern void eNotify_removeWatch(int);

void eNotifyCallback(int watchID, int action, const char* rootPath, const char* filePath);