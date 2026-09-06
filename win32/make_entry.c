#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SLOT_SIZE 128
#define MARKER "__CMDLET_TARGET_PLACEHOLDER__"

__asm__(
    ".section .rodata\n"
    ".global template_begin\n"
    "template_begin:\n"
    ".incbin \"template.exe\"\n"
    ".global template_end\n"
    "template_end:\n"
    ".section .text\n"  // 平滑切回标准代码段，不污染后续 C 语法
);

extern const unsigned char template_begin[];
extern const unsigned char template_end[];

int main(int argc, char* argv[]) {
  const char* source = argv[1];
  const char* target = argv[2];

  unsigned int size = (unsigned int)(template_end - template_begin);
  unsigned char* buffer = malloc(size);
  if (!buffer) {
    perror("错误: 内存分配失败！");
    return 1;
  }

  memcpy(buffer, template_begin, size);

  // 在内存中用地毯式激光雷达扫描黄金特征码
  long marker_len = strlen(MARKER);
  int ret = -1;
  for (long i = 0; i <= size - marker_len; i++) {
    if (memcmp(&buffer[i], MARKER, marker_len) == 0) {
      memset(&buffer[i], 0, SLOT_SIZE);
      memcpy(&buffer[i], source, strlen(source));

      FILE* f_out = fopen(target, "wb");
      if (!f_out) {
        perror("错误: 无法创建输出可执行文件");
        free(buffer);
        return 1;
      }
      fwrite(buffer, 1, size, f_out);
      fclose(f_out);

      printf("%s -> %s\n", target, source);

      ret = 0;
      break;
    }
  }

  free(buffer);
  return ret;
}
