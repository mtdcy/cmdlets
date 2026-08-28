#include <process.h>
#include <stdio.h>
#include <string.h>
#include <windows.h>

int main(int argc, const char* const argv[]) {
  char exe_path[MAX_PATH];
  GetModuleFileNameA(NULL, exe_path, MAX_PATH);

  // 1. 优先寻找 Linux 风格的正斜杠 '/'
  char* last_slash = strrchr(exe_path, '/');

  // 2. 如果没找到，说明处于纯正的 Windows 实机物理环境，改找反斜杠 '\\'
  if (last_slash == NULL) {
    last_slash = strrchr(exe_path, '\\');
  }

  // 3. 执行路径裁剪，保留当前目录的绝对路径部分
  if (last_slash != NULL) {
    *(last_slash + 1) = '\0';
  }

  // 4. 动态拼接在同一目录下的真实目标文件名（由编译参数 -D 注入，如
  // "main_tool.exe"）
  strcat(exe_path, TARGET);

  // printf("%s\n", exe_path);

  // 5. 完美无损透传参数，原地替换进程
  _execv(exe_path, argv);

  return 127;
}
