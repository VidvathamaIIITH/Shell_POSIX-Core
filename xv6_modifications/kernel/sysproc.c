#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_waitx(void)
{
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
  argaddr(1, &addr1); // user virtual memory
  argaddr(2, &addr2);
  int ret = waitx(addr, &wtime, &rtime);
  struct proc *p = myproc();
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    return -1;
  return ret;
}

uint64
sys_getSysCount(void) {
  int mask;
  argint(0, &mask);
  return getSysCount(mask);
}

uint64
sys_sigalarm(void) {
    int interval;
    void (*handler)();

    // Get the arguments from the user
    argint(0, &interval);
    argaddr(1, (uint64*)&handler);
    struct proc *p = myproc();  // Get current process
    p->alarmticks = interval;
    p->ticks_left = interval;
    p->alarm_handler = handler;
    p->in_alarm = 0; // Ensure we are not inside an alarm handler yet

    return 0;
}

uint64
sys_sigreturn(void) {
    struct proc *p = myproc();

    // Restore the original trapframe to resume the process as it was before the handler
    memmove(p->trapframe, p->original_trapframe, sizeof(struct trapframe));
    struct trapframe *tf = p->original_trapframe;
    // Restore the registers from the original trapframe
    // Restore a0
    asm volatile("mv a0, %0" : : "r"(tf->a0));
    // Restore other registers as necessary
    asm volatile("mv a1, %0" : : "r"(tf->a1));
    asm volatile("mv a2, %0" : : "r"(tf->a2));
    // Continue for other registers...

    // Restore the program counter
    asm volatile("mv ra, %0" : : "r"(tf->ra));
    uint64 a0;
    asm volatile("mv %0, a0" : "=r"(a0));

    p->in_alarm = 0;  // Reset the alarm state

    return a0;
}

uint64
sys_settickets(void) {
  int n;
  argint(0, &n);
  if(n < 1)
    return -1;
  struct proc *p = myproc();
  p->tickets = n;
  return n;
}
