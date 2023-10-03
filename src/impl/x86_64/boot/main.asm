global start
extern long_mode_start

section .text
bits 32
start:
  ; setup a stack
  mov esp, stack_top

  call check_multiboot
  call check_cpuid
  call check_long_mode

  call setup_page_tables
  call enable_paging

  lgdt [gdt64.pointer]
  jmp gdt64.code_segment:long_mode_start

  hlt
  
check_multiboot:
  cmp eax, 0x36d76289
  jne .no_multiboot
  ret
.no_multiboot:
  mov al, "M" ; error code "M" for multiboot
  jmp error

check_cpuid:
  ; flip ID bit of flags register and push it back. if the bit stays flipped, CPU supports cpuid
  pushfd  ; push flag register on the stack
  pop eax ; pop stack onto eax
  mov ecx, eax ; store value for restore a couple instructions down
  xor eax, 1 << 21 ; flip bit 21
  push eax ; push back onto stack
  popfd    ; then into flags register
  pushfd   ; read it back on stack
  pop eax  ; move it to eax
  push ecx ; push original value onto stack
  popfd    ; restore flags register
  cmp eax, ecx
  je .no_cpuid
  ret
.no_cpuid:
  mov al, "C" ; error code "C" for no CPUID support
  jmp error

check_long_mode:
  mov eax, 0x80000000 ; does CPUID support extended processor info
  cpuid
  cmp eax, 0x80000001 ; if eax larger than 0x80000000, CPU supports extended processor info
  jb .no_long_mode    ; if not, CPU does not support long mode

  mov eax, 0x80000001 ; now check if long mode is available
  cpuid
  test edx, 1 << 29   ; if LM bit is set, cPU support long mode
  jz .no_long_mode

  ret
.no_long_mode:
  mov al, "L" ; error code "L" for no long mode support
  jmp error

setup_page_tables:
  ; identity map the begining of virtual space to physical space to enable code to continue running from physical to virtual when paging is enabled
  mov eax, page_table_l3
  or eax, 0b11 ; add present, writable flags into unused portion of address
  mov [page_table_l4], eax ; move first and only l3 table to begin of l4 table

  ; do the same for l3 table
  mov eax, page_table_l2
  or eax, 0b11 ; add present, writable flags into unused portion of address
  mov [page_table_l3], eax

  ; for l2 table, we won't have l1 tables, we'll use huge pages instead
  mov ecx, 0 ; counter
.loop:
  mov eax, 0x200000 ; 2MB, size of a huge page
  mul ecx           ; multiply by counter
  or eax, 0b10000011 ; add present, writable, huge page flags into unused portion of address
  mov [page_table_l2 + ecx * 8], eax
  
  inc ecx
  cmp ecx, 512 ; check if whole table has been mapped
  jne .loop

  ret

enable_paging:
  ; give CPU the address of the L4 table
  mov eax, page_table_l4
  mov cr3, eax
  ; enable PAE (physical address extension)
  mov eax, cr4
  or eax, 1 << 5
  mov cr4, eax;
  ; enable long mode - we will not enter 64-bit mode yet
  mov ecx, 0xc0000080
  rdmsr
  or eax, 1 << 8
  wrmsr
  ; enable paging
  mov eax, cr0
  or eax, 1 << 31
  mov cr0, eax

  ret

error:
  ; print "ERR: X" where X is the error code
  mov dword [0xb8000], 0x4f524f45
  mov dword [0xb8004], 0x4f3a4f52
  mov dword [0xb8008], 0x4f204f20
  mov byte  [0xb800a], al
  hlt

section .bss
align 4096
page_table_l4:
  resb 4096
page_table_l3:
  resb 4096
page_table_l2:
  resb 4096
stack_bottom:
  resb 4096 * 4
stack_top:

; global descriptor table
section .rodata
gdt64:
  dq 0 ; zero entry
.code_segment: equ $ - gdt64
  dq (1 << 43) | (1 << 44) | (1 << 47) | (1 << 53) ; code segment
.pointer:
  dw $ - gdt64 - 1
  dq gdt64
