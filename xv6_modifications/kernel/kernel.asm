
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000b117          	auipc	sp,0xb
    80000004:	36013103          	ld	sp,864(sp) # 8000b360 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	1761                	addi	a4,a4,-8 # 200bff8 <_entry-0x7dff4008>
    8000003a:	6318                	ld	a4,0(a4)
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	0000b717          	auipc	a4,0xb
    80000054:	37070713          	addi	a4,a4,880 # 8000b3c0 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	2ce78793          	addi	a5,a5,718 # 80006330 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd71cf>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e2678793          	addi	a5,a5,-474 # 80000ed2 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	f84a                	sd	s2,48(sp)
    80000108:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    8000010a:	04c05663          	blez	a2,80000156 <consolewrite+0x56>
    8000010e:	fc26                	sd	s1,56(sp)
    80000110:	f44e                	sd	s3,40(sp)
    80000112:	f052                	sd	s4,32(sp)
    80000114:	ec56                	sd	s5,24(sp)
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	616080e7          	jalr	1558(ra) # 80002740 <either_copyin>
    80000132:	03550463          	beq	a0,s5,8000015a <consolewrite+0x5a>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	7e4080e7          	jalr	2020(ra) # 8000091e <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
    8000014c:	74e2                	ld	s1,56(sp)
    8000014e:	79a2                	ld	s3,40(sp)
    80000150:	7a02                	ld	s4,32(sp)
    80000152:	6ae2                	ld	s5,24(sp)
    80000154:	a039                	j	80000162 <consolewrite+0x62>
    80000156:	4901                	li	s2,0
    80000158:	a029                	j	80000162 <consolewrite+0x62>
    8000015a:	74e2                	ld	s1,56(sp)
    8000015c:	79a2                	ld	s3,40(sp)
    8000015e:	7a02                	ld	s4,32(sp)
    80000160:	6ae2                	ld	s5,24(sp)
  }

  return i;
}
    80000162:	854a                	mv	a0,s2
    80000164:	60a6                	ld	ra,72(sp)
    80000166:	6406                	ld	s0,64(sp)
    80000168:	7942                	ld	s2,48(sp)
    8000016a:	6161                	addi	sp,sp,80
    8000016c:	8082                	ret

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	711d                	addi	sp,sp,-96
    80000170:	ec86                	sd	ra,88(sp)
    80000172:	e8a2                	sd	s0,80(sp)
    80000174:	e4a6                	sd	s1,72(sp)
    80000176:	e0ca                	sd	s2,64(sp)
    80000178:	fc4e                	sd	s3,56(sp)
    8000017a:	f852                	sd	s4,48(sp)
    8000017c:	f456                	sd	s5,40(sp)
    8000017e:	f05a                	sd	s6,32(sp)
    80000180:	1080                	addi	s0,sp,96
    80000182:	8aaa                	mv	s5,a0
    80000184:	8a2e                	mv	s4,a1
    80000186:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018c:	00013517          	auipc	a0,0x13
    80000190:	37450513          	addi	a0,a0,884 # 80013500 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	aa4080e7          	jalr	-1372(ra) # 80000c38 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00013497          	auipc	s1,0x13
    800001a0:	36448493          	addi	s1,s1,868 # 80013500 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	00013917          	auipc	s2,0x13
    800001a8:	3f490913          	addi	s2,s2,1012 # 80013598 <cons+0x98>
  while(n > 0){
    800001ac:	0d305763          	blez	s3,8000027a <consoleread+0x10c>
    while(cons.r == cons.w){
    800001b0:	0984a783          	lw	a5,152(s1)
    800001b4:	09c4a703          	lw	a4,156(s1)
    800001b8:	0af71c63          	bne	a4,a5,80000270 <consoleread+0x102>
      if(killed(myproc())){
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	88e080e7          	jalr	-1906(ra) # 80001a4a <myproc>
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	3aa080e7          	jalr	938(ra) # 8000256e <killed>
    800001cc:	e52d                	bnez	a0,80000236 <consoleread+0xc8>
      sleep(&cons.r, &cons.lock);
    800001ce:	85a6                	mv	a1,s1
    800001d0:	854a                	mv	a0,s2
    800001d2:	00002097          	auipc	ra,0x2
    800001d6:	0dc080e7          	jalr	220(ra) # 800022ae <sleep>
    while(cons.r == cons.w){
    800001da:	0984a783          	lw	a5,152(s1)
    800001de:	09c4a703          	lw	a4,156(s1)
    800001e2:	fcf70de3          	beq	a4,a5,800001bc <consoleread+0x4e>
    800001e6:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001e8:	00013717          	auipc	a4,0x13
    800001ec:	31870713          	addi	a4,a4,792 # 80013500 <cons>
    800001f0:	0017869b          	addiw	a3,a5,1
    800001f4:	08d72c23          	sw	a3,152(a4)
    800001f8:	07f7f693          	andi	a3,a5,127
    800001fc:	9736                	add	a4,a4,a3
    800001fe:	01874703          	lbu	a4,24(a4)
    80000202:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    80000206:	4691                	li	a3,4
    80000208:	04db8a63          	beq	s7,a3,8000025c <consoleread+0xee>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    8000020c:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	faf40613          	addi	a2,s0,-81
    80000216:	85d2                	mv	a1,s4
    80000218:	8556                	mv	a0,s5
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	4d0080e7          	jalr	1232(ra) # 800026ea <either_copyout>
    80000222:	57fd                	li	a5,-1
    80000224:	04f50a63          	beq	a0,a5,80000278 <consoleread+0x10a>
      break;

    dst++;
    80000228:	0a05                	addi	s4,s4,1
    --n;
    8000022a:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    8000022c:	47a9                	li	a5,10
    8000022e:	06fb8163          	beq	s7,a5,80000290 <consoleread+0x122>
    80000232:	6be2                	ld	s7,24(sp)
    80000234:	bfa5                	j	800001ac <consoleread+0x3e>
        release(&cons.lock);
    80000236:	00013517          	auipc	a0,0x13
    8000023a:	2ca50513          	addi	a0,a0,714 # 80013500 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	aae080e7          	jalr	-1362(ra) # 80000cec <release>
        return -1;
    80000246:	557d                	li	a0,-1
    }
  }
  release(&cons.lock);

  return target - n;
}
    80000248:	60e6                	ld	ra,88(sp)
    8000024a:	6446                	ld	s0,80(sp)
    8000024c:	64a6                	ld	s1,72(sp)
    8000024e:	6906                	ld	s2,64(sp)
    80000250:	79e2                	ld	s3,56(sp)
    80000252:	7a42                	ld	s4,48(sp)
    80000254:	7aa2                	ld	s5,40(sp)
    80000256:	7b02                	ld	s6,32(sp)
    80000258:	6125                	addi	sp,sp,96
    8000025a:	8082                	ret
      if(n < target){
    8000025c:	0009871b          	sext.w	a4,s3
    80000260:	01677a63          	bgeu	a4,s6,80000274 <consoleread+0x106>
        cons.r--;
    80000264:	00013717          	auipc	a4,0x13
    80000268:	32f72a23          	sw	a5,820(a4) # 80013598 <cons+0x98>
    8000026c:	6be2                	ld	s7,24(sp)
    8000026e:	a031                	j	8000027a <consoleread+0x10c>
    80000270:	ec5e                	sd	s7,24(sp)
    80000272:	bf9d                	j	800001e8 <consoleread+0x7a>
    80000274:	6be2                	ld	s7,24(sp)
    80000276:	a011                	j	8000027a <consoleread+0x10c>
    80000278:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    8000027a:	00013517          	auipc	a0,0x13
    8000027e:	28650513          	addi	a0,a0,646 # 80013500 <cons>
    80000282:	00001097          	auipc	ra,0x1
    80000286:	a6a080e7          	jalr	-1430(ra) # 80000cec <release>
  return target - n;
    8000028a:	413b053b          	subw	a0,s6,s3
    8000028e:	bf6d                	j	80000248 <consoleread+0xda>
    80000290:	6be2                	ld	s7,24(sp)
    80000292:	b7e5                	j	8000027a <consoleread+0x10c>

0000000080000294 <consputc>:
{
    80000294:	1141                	addi	sp,sp,-16
    80000296:	e406                	sd	ra,8(sp)
    80000298:	e022                	sd	s0,0(sp)
    8000029a:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000029c:	10000793          	li	a5,256
    800002a0:	00f50a63          	beq	a0,a5,800002b4 <consputc+0x20>
    uartputc_sync(c);
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	59c080e7          	jalr	1436(ra) # 80000840 <uartputc_sync>
}
    800002ac:	60a2                	ld	ra,8(sp)
    800002ae:	6402                	ld	s0,0(sp)
    800002b0:	0141                	addi	sp,sp,16
    800002b2:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002b4:	4521                	li	a0,8
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	58a080e7          	jalr	1418(ra) # 80000840 <uartputc_sync>
    800002be:	02000513          	li	a0,32
    800002c2:	00000097          	auipc	ra,0x0
    800002c6:	57e080e7          	jalr	1406(ra) # 80000840 <uartputc_sync>
    800002ca:	4521                	li	a0,8
    800002cc:	00000097          	auipc	ra,0x0
    800002d0:	574080e7          	jalr	1396(ra) # 80000840 <uartputc_sync>
    800002d4:	bfe1                	j	800002ac <consputc+0x18>

00000000800002d6 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002d6:	1101                	addi	sp,sp,-32
    800002d8:	ec06                	sd	ra,24(sp)
    800002da:	e822                	sd	s0,16(sp)
    800002dc:	e426                	sd	s1,8(sp)
    800002de:	1000                	addi	s0,sp,32
    800002e0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002e2:	00013517          	auipc	a0,0x13
    800002e6:	21e50513          	addi	a0,a0,542 # 80013500 <cons>
    800002ea:	00001097          	auipc	ra,0x1
    800002ee:	94e080e7          	jalr	-1714(ra) # 80000c38 <acquire>

  switch(c){
    800002f2:	47d5                	li	a5,21
    800002f4:	0af48563          	beq	s1,a5,8000039e <consoleintr+0xc8>
    800002f8:	0297c963          	blt	a5,s1,8000032a <consoleintr+0x54>
    800002fc:	47a1                	li	a5,8
    800002fe:	0ef48c63          	beq	s1,a5,800003f6 <consoleintr+0x120>
    80000302:	47c1                	li	a5,16
    80000304:	10f49f63          	bne	s1,a5,80000422 <consoleintr+0x14c>
  case C('P'):  // Print process list.
    procdump();
    80000308:	00002097          	auipc	ra,0x2
    8000030c:	48e080e7          	jalr	1166(ra) # 80002796 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000310:	00013517          	auipc	a0,0x13
    80000314:	1f050513          	addi	a0,a0,496 # 80013500 <cons>
    80000318:	00001097          	auipc	ra,0x1
    8000031c:	9d4080e7          	jalr	-1580(ra) # 80000cec <release>
}
    80000320:	60e2                	ld	ra,24(sp)
    80000322:	6442                	ld	s0,16(sp)
    80000324:	64a2                	ld	s1,8(sp)
    80000326:	6105                	addi	sp,sp,32
    80000328:	8082                	ret
  switch(c){
    8000032a:	07f00793          	li	a5,127
    8000032e:	0cf48463          	beq	s1,a5,800003f6 <consoleintr+0x120>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000332:	00013717          	auipc	a4,0x13
    80000336:	1ce70713          	addi	a4,a4,462 # 80013500 <cons>
    8000033a:	0a072783          	lw	a5,160(a4)
    8000033e:	09872703          	lw	a4,152(a4)
    80000342:	9f99                	subw	a5,a5,a4
    80000344:	07f00713          	li	a4,127
    80000348:	fcf764e3          	bltu	a4,a5,80000310 <consoleintr+0x3a>
      c = (c == '\r') ? '\n' : c;
    8000034c:	47b5                	li	a5,13
    8000034e:	0cf48d63          	beq	s1,a5,80000428 <consoleintr+0x152>
      consputc(c);
    80000352:	8526                	mv	a0,s1
    80000354:	00000097          	auipc	ra,0x0
    80000358:	f40080e7          	jalr	-192(ra) # 80000294 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000035c:	00013797          	auipc	a5,0x13
    80000360:	1a478793          	addi	a5,a5,420 # 80013500 <cons>
    80000364:	0a07a683          	lw	a3,160(a5)
    80000368:	0016871b          	addiw	a4,a3,1
    8000036c:	0007061b          	sext.w	a2,a4
    80000370:	0ae7a023          	sw	a4,160(a5)
    80000374:	07f6f693          	andi	a3,a3,127
    80000378:	97b6                	add	a5,a5,a3
    8000037a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000037e:	47a9                	li	a5,10
    80000380:	0cf48b63          	beq	s1,a5,80000456 <consoleintr+0x180>
    80000384:	4791                	li	a5,4
    80000386:	0cf48863          	beq	s1,a5,80000456 <consoleintr+0x180>
    8000038a:	00013797          	auipc	a5,0x13
    8000038e:	20e7a783          	lw	a5,526(a5) # 80013598 <cons+0x98>
    80000392:	9f1d                	subw	a4,a4,a5
    80000394:	08000793          	li	a5,128
    80000398:	f6f71ce3          	bne	a4,a5,80000310 <consoleintr+0x3a>
    8000039c:	a86d                	j	80000456 <consoleintr+0x180>
    8000039e:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    800003a0:	00013717          	auipc	a4,0x13
    800003a4:	16070713          	addi	a4,a4,352 # 80013500 <cons>
    800003a8:	0a072783          	lw	a5,160(a4)
    800003ac:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003b0:	00013497          	auipc	s1,0x13
    800003b4:	15048493          	addi	s1,s1,336 # 80013500 <cons>
    while(cons.e != cons.w &&
    800003b8:	4929                	li	s2,10
    800003ba:	02f70a63          	beq	a4,a5,800003ee <consoleintr+0x118>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003be:	37fd                	addiw	a5,a5,-1
    800003c0:	07f7f713          	andi	a4,a5,127
    800003c4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c6:	01874703          	lbu	a4,24(a4)
    800003ca:	03270463          	beq	a4,s2,800003f2 <consoleintr+0x11c>
      cons.e--;
    800003ce:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003d2:	10000513          	li	a0,256
    800003d6:	00000097          	auipc	ra,0x0
    800003da:	ebe080e7          	jalr	-322(ra) # 80000294 <consputc>
    while(cons.e != cons.w &&
    800003de:	0a04a783          	lw	a5,160(s1)
    800003e2:	09c4a703          	lw	a4,156(s1)
    800003e6:	fcf71ce3          	bne	a4,a5,800003be <consoleintr+0xe8>
    800003ea:	6902                	ld	s2,0(sp)
    800003ec:	b715                	j	80000310 <consoleintr+0x3a>
    800003ee:	6902                	ld	s2,0(sp)
    800003f0:	b705                	j	80000310 <consoleintr+0x3a>
    800003f2:	6902                	ld	s2,0(sp)
    800003f4:	bf31                	j	80000310 <consoleintr+0x3a>
    if(cons.e != cons.w){
    800003f6:	00013717          	auipc	a4,0x13
    800003fa:	10a70713          	addi	a4,a4,266 # 80013500 <cons>
    800003fe:	0a072783          	lw	a5,160(a4)
    80000402:	09c72703          	lw	a4,156(a4)
    80000406:	f0f705e3          	beq	a4,a5,80000310 <consoleintr+0x3a>
      cons.e--;
    8000040a:	37fd                	addiw	a5,a5,-1
    8000040c:	00013717          	auipc	a4,0x13
    80000410:	18f72a23          	sw	a5,404(a4) # 800135a0 <cons+0xa0>
      consputc(BACKSPACE);
    80000414:	10000513          	li	a0,256
    80000418:	00000097          	auipc	ra,0x0
    8000041c:	e7c080e7          	jalr	-388(ra) # 80000294 <consputc>
    80000420:	bdc5                	j	80000310 <consoleintr+0x3a>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000422:	ee0487e3          	beqz	s1,80000310 <consoleintr+0x3a>
    80000426:	b731                	j	80000332 <consoleintr+0x5c>
      consputc(c);
    80000428:	4529                	li	a0,10
    8000042a:	00000097          	auipc	ra,0x0
    8000042e:	e6a080e7          	jalr	-406(ra) # 80000294 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000432:	00013797          	auipc	a5,0x13
    80000436:	0ce78793          	addi	a5,a5,206 # 80013500 <cons>
    8000043a:	0a07a703          	lw	a4,160(a5)
    8000043e:	0017069b          	addiw	a3,a4,1
    80000442:	0006861b          	sext.w	a2,a3
    80000446:	0ad7a023          	sw	a3,160(a5)
    8000044a:	07f77713          	andi	a4,a4,127
    8000044e:	97ba                	add	a5,a5,a4
    80000450:	4729                	li	a4,10
    80000452:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000456:	00013797          	auipc	a5,0x13
    8000045a:	14c7a323          	sw	a2,326(a5) # 8001359c <cons+0x9c>
        wakeup(&cons.r);
    8000045e:	00013517          	auipc	a0,0x13
    80000462:	13a50513          	addi	a0,a0,314 # 80013598 <cons+0x98>
    80000466:	00002097          	auipc	ra,0x2
    8000046a:	eac080e7          	jalr	-340(ra) # 80002312 <wakeup>
    8000046e:	b54d                	j	80000310 <consoleintr+0x3a>

0000000080000470 <consoleinit>:

void
consoleinit(void)
{
    80000470:	1141                	addi	sp,sp,-16
    80000472:	e406                	sd	ra,8(sp)
    80000474:	e022                	sd	s0,0(sp)
    80000476:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000478:	00008597          	auipc	a1,0x8
    8000047c:	b8858593          	addi	a1,a1,-1144 # 80008000 <etext>
    80000480:	00013517          	auipc	a0,0x13
    80000484:	08050513          	addi	a0,a0,128 # 80013500 <cons>
    80000488:	00000097          	auipc	ra,0x0
    8000048c:	720080e7          	jalr	1824(ra) # 80000ba8 <initlock>

  uartinit();
    80000490:	00000097          	auipc	ra,0x0
    80000494:	354080e7          	jalr	852(ra) # 800007e4 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000498:	00026797          	auipc	a5,0x26
    8000049c:	00078793          	mv	a5,a5
    800004a0:	00000717          	auipc	a4,0x0
    800004a4:	cce70713          	addi	a4,a4,-818 # 8000016e <consoleread>
    800004a8:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800004aa:	00000717          	auipc	a4,0x0
    800004ae:	c5670713          	addi	a4,a4,-938 # 80000100 <consolewrite>
    800004b2:	ef98                	sd	a4,24(a5)
}
    800004b4:	60a2                	ld	ra,8(sp)
    800004b6:	6402                	ld	s0,0(sp)
    800004b8:	0141                	addi	sp,sp,16
    800004ba:	8082                	ret

00000000800004bc <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004bc:	7179                	addi	sp,sp,-48
    800004be:	f406                	sd	ra,40(sp)
    800004c0:	f022                	sd	s0,32(sp)
    800004c2:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004c4:	c219                	beqz	a2,800004ca <printint+0xe>
    800004c6:	08054963          	bltz	a0,80000558 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ca:	2501                	sext.w	a0,a0
    800004cc:	4881                	li	a7,0
    800004ce:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004d2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004d4:	2581                	sext.w	a1,a1
    800004d6:	00008617          	auipc	a2,0x8
    800004da:	26a60613          	addi	a2,a2,618 # 80008740 <digits>
    800004de:	883a                	mv	a6,a4
    800004e0:	2705                	addiw	a4,a4,1
    800004e2:	02b577bb          	remuw	a5,a0,a1
    800004e6:	1782                	slli	a5,a5,0x20
    800004e8:	9381                	srli	a5,a5,0x20
    800004ea:	97b2                	add	a5,a5,a2
    800004ec:	0007c783          	lbu	a5,0(a5) # 80026498 <devsw>
    800004f0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004f4:	0005079b          	sext.w	a5,a0
    800004f8:	02b5553b          	divuw	a0,a0,a1
    800004fc:	0685                	addi	a3,a3,1
    800004fe:	feb7f0e3          	bgeu	a5,a1,800004de <printint+0x22>

  if(sign)
    80000502:	00088c63          	beqz	a7,8000051a <printint+0x5e>
    buf[i++] = '-';
    80000506:	fe070793          	addi	a5,a4,-32
    8000050a:	00878733          	add	a4,a5,s0
    8000050e:	02d00793          	li	a5,45
    80000512:	fef70823          	sb	a5,-16(a4)
    80000516:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000051a:	02e05b63          	blez	a4,80000550 <printint+0x94>
    8000051e:	ec26                	sd	s1,24(sp)
    80000520:	e84a                	sd	s2,16(sp)
    80000522:	fd040793          	addi	a5,s0,-48
    80000526:	00e784b3          	add	s1,a5,a4
    8000052a:	fff78913          	addi	s2,a5,-1
    8000052e:	993a                	add	s2,s2,a4
    80000530:	377d                	addiw	a4,a4,-1
    80000532:	1702                	slli	a4,a4,0x20
    80000534:	9301                	srli	a4,a4,0x20
    80000536:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000053a:	fff4c503          	lbu	a0,-1(s1)
    8000053e:	00000097          	auipc	ra,0x0
    80000542:	d56080e7          	jalr	-682(ra) # 80000294 <consputc>
  while(--i >= 0)
    80000546:	14fd                	addi	s1,s1,-1
    80000548:	ff2499e3          	bne	s1,s2,8000053a <printint+0x7e>
    8000054c:	64e2                	ld	s1,24(sp)
    8000054e:	6942                	ld	s2,16(sp)
}
    80000550:	70a2                	ld	ra,40(sp)
    80000552:	7402                	ld	s0,32(sp)
    80000554:	6145                	addi	sp,sp,48
    80000556:	8082                	ret
    x = -xx;
    80000558:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000055c:	4885                	li	a7,1
    x = -xx;
    8000055e:	bf85                	j	800004ce <printint+0x12>

0000000080000560 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000560:	1101                	addi	sp,sp,-32
    80000562:	ec06                	sd	ra,24(sp)
    80000564:	e822                	sd	s0,16(sp)
    80000566:	e426                	sd	s1,8(sp)
    80000568:	1000                	addi	s0,sp,32
    8000056a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000056c:	00013797          	auipc	a5,0x13
    80000570:	0407aa23          	sw	zero,84(a5) # 800135c0 <pr+0x18>
  printf("panic: ");
    80000574:	00008517          	auipc	a0,0x8
    80000578:	a9450513          	addi	a0,a0,-1388 # 80008008 <etext+0x8>
    8000057c:	00000097          	auipc	ra,0x0
    80000580:	02e080e7          	jalr	46(ra) # 800005aa <printf>
  printf(s);
    80000584:	8526                	mv	a0,s1
    80000586:	00000097          	auipc	ra,0x0
    8000058a:	024080e7          	jalr	36(ra) # 800005aa <printf>
  printf("\n");
    8000058e:	00008517          	auipc	a0,0x8
    80000592:	a8250513          	addi	a0,a0,-1406 # 80008010 <etext+0x10>
    80000596:	00000097          	auipc	ra,0x0
    8000059a:	014080e7          	jalr	20(ra) # 800005aa <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000059e:	4785                	li	a5,1
    800005a0:	0000b717          	auipc	a4,0xb
    800005a4:	def72023          	sw	a5,-544(a4) # 8000b380 <panicked>
  for(;;)
    800005a8:	a001                	j	800005a8 <panic+0x48>

00000000800005aa <printf>:
{
    800005aa:	7131                	addi	sp,sp,-192
    800005ac:	fc86                	sd	ra,120(sp)
    800005ae:	f8a2                	sd	s0,112(sp)
    800005b0:	e8d2                	sd	s4,80(sp)
    800005b2:	f06a                	sd	s10,32(sp)
    800005b4:	0100                	addi	s0,sp,128
    800005b6:	8a2a                	mv	s4,a0
    800005b8:	e40c                	sd	a1,8(s0)
    800005ba:	e810                	sd	a2,16(s0)
    800005bc:	ec14                	sd	a3,24(s0)
    800005be:	f018                	sd	a4,32(s0)
    800005c0:	f41c                	sd	a5,40(s0)
    800005c2:	03043823          	sd	a6,48(s0)
    800005c6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ca:	00013d17          	auipc	s10,0x13
    800005ce:	ff6d2d03          	lw	s10,-10(s10) # 800135c0 <pr+0x18>
  if(locking)
    800005d2:	040d1463          	bnez	s10,8000061a <printf+0x70>
  if (fmt == 0)
    800005d6:	040a0b63          	beqz	s4,8000062c <printf+0x82>
  va_start(ap, fmt);
    800005da:	00840793          	addi	a5,s0,8
    800005de:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e2:	000a4503          	lbu	a0,0(s4)
    800005e6:	18050b63          	beqz	a0,8000077c <printf+0x1d2>
    800005ea:	f4a6                	sd	s1,104(sp)
    800005ec:	f0ca                	sd	s2,96(sp)
    800005ee:	ecce                	sd	s3,88(sp)
    800005f0:	e4d6                	sd	s5,72(sp)
    800005f2:	e0da                	sd	s6,64(sp)
    800005f4:	fc5e                	sd	s7,56(sp)
    800005f6:	f862                	sd	s8,48(sp)
    800005f8:	f466                	sd	s9,40(sp)
    800005fa:	ec6e                	sd	s11,24(sp)
    800005fc:	4981                	li	s3,0
    if(c != '%'){
    800005fe:	02500b13          	li	s6,37
    switch(c){
    80000602:	07000b93          	li	s7,112
  consputc('x');
    80000606:	4cc1                	li	s9,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000608:	00008a97          	auipc	s5,0x8
    8000060c:	138a8a93          	addi	s5,s5,312 # 80008740 <digits>
    switch(c){
    80000610:	07300c13          	li	s8,115
    80000614:	06400d93          	li	s11,100
    80000618:	a0b1                	j	80000664 <printf+0xba>
    acquire(&pr.lock);
    8000061a:	00013517          	auipc	a0,0x13
    8000061e:	f8e50513          	addi	a0,a0,-114 # 800135a8 <pr>
    80000622:	00000097          	auipc	ra,0x0
    80000626:	616080e7          	jalr	1558(ra) # 80000c38 <acquire>
    8000062a:	b775                	j	800005d6 <printf+0x2c>
    8000062c:	f4a6                	sd	s1,104(sp)
    8000062e:	f0ca                	sd	s2,96(sp)
    80000630:	ecce                	sd	s3,88(sp)
    80000632:	e4d6                	sd	s5,72(sp)
    80000634:	e0da                	sd	s6,64(sp)
    80000636:	fc5e                	sd	s7,56(sp)
    80000638:	f862                	sd	s8,48(sp)
    8000063a:	f466                	sd	s9,40(sp)
    8000063c:	ec6e                	sd	s11,24(sp)
    panic("null fmt");
    8000063e:	00008517          	auipc	a0,0x8
    80000642:	9e250513          	addi	a0,a0,-1566 # 80008020 <etext+0x20>
    80000646:	00000097          	auipc	ra,0x0
    8000064a:	f1a080e7          	jalr	-230(ra) # 80000560 <panic>
      consputc(c);
    8000064e:	00000097          	auipc	ra,0x0
    80000652:	c46080e7          	jalr	-954(ra) # 80000294 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000656:	2985                	addiw	s3,s3,1
    80000658:	013a07b3          	add	a5,s4,s3
    8000065c:	0007c503          	lbu	a0,0(a5)
    80000660:	10050563          	beqz	a0,8000076a <printf+0x1c0>
    if(c != '%'){
    80000664:	ff6515e3          	bne	a0,s6,8000064e <printf+0xa4>
    c = fmt[++i] & 0xff;
    80000668:	2985                	addiw	s3,s3,1
    8000066a:	013a07b3          	add	a5,s4,s3
    8000066e:	0007c783          	lbu	a5,0(a5)
    80000672:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000676:	10078b63          	beqz	a5,8000078c <printf+0x1e2>
    switch(c){
    8000067a:	05778a63          	beq	a5,s7,800006ce <printf+0x124>
    8000067e:	02fbf663          	bgeu	s7,a5,800006aa <printf+0x100>
    80000682:	09878863          	beq	a5,s8,80000712 <printf+0x168>
    80000686:	07800713          	li	a4,120
    8000068a:	0ce79563          	bne	a5,a4,80000754 <printf+0x1aa>
      printint(va_arg(ap, int), 16, 1);
    8000068e:	f8843783          	ld	a5,-120(s0)
    80000692:	00878713          	addi	a4,a5,8
    80000696:	f8e43423          	sd	a4,-120(s0)
    8000069a:	4605                	li	a2,1
    8000069c:	85e6                	mv	a1,s9
    8000069e:	4388                	lw	a0,0(a5)
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	e1c080e7          	jalr	-484(ra) # 800004bc <printint>
      break;
    800006a8:	b77d                	j	80000656 <printf+0xac>
    switch(c){
    800006aa:	09678f63          	beq	a5,s6,80000748 <printf+0x19e>
    800006ae:	0bb79363          	bne	a5,s11,80000754 <printf+0x1aa>
      printint(va_arg(ap, int), 10, 1);
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	4605                	li	a2,1
    800006c0:	45a9                	li	a1,10
    800006c2:	4388                	lw	a0,0(a5)
    800006c4:	00000097          	auipc	ra,0x0
    800006c8:	df8080e7          	jalr	-520(ra) # 800004bc <printint>
      break;
    800006cc:	b769                	j	80000656 <printf+0xac>
      printptr(va_arg(ap, uint64));
    800006ce:	f8843783          	ld	a5,-120(s0)
    800006d2:	00878713          	addi	a4,a5,8
    800006d6:	f8e43423          	sd	a4,-120(s0)
    800006da:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006de:	03000513          	li	a0,48
    800006e2:	00000097          	auipc	ra,0x0
    800006e6:	bb2080e7          	jalr	-1102(ra) # 80000294 <consputc>
  consputc('x');
    800006ea:	07800513          	li	a0,120
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	ba6080e7          	jalr	-1114(ra) # 80000294 <consputc>
    800006f6:	84e6                	mv	s1,s9
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006f8:	03c95793          	srli	a5,s2,0x3c
    800006fc:	97d6                	add	a5,a5,s5
    800006fe:	0007c503          	lbu	a0,0(a5)
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b92080e7          	jalr	-1134(ra) # 80000294 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000070a:	0912                	slli	s2,s2,0x4
    8000070c:	34fd                	addiw	s1,s1,-1
    8000070e:	f4ed                	bnez	s1,800006f8 <printf+0x14e>
    80000710:	b799                	j	80000656 <printf+0xac>
      if((s = va_arg(ap, char*)) == 0)
    80000712:	f8843783          	ld	a5,-120(s0)
    80000716:	00878713          	addi	a4,a5,8
    8000071a:	f8e43423          	sd	a4,-120(s0)
    8000071e:	6384                	ld	s1,0(a5)
    80000720:	cc89                	beqz	s1,8000073a <printf+0x190>
      for(; *s; s++)
    80000722:	0004c503          	lbu	a0,0(s1)
    80000726:	d905                	beqz	a0,80000656 <printf+0xac>
        consputc(*s);
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b6c080e7          	jalr	-1172(ra) # 80000294 <consputc>
      for(; *s; s++)
    80000730:	0485                	addi	s1,s1,1
    80000732:	0004c503          	lbu	a0,0(s1)
    80000736:	f96d                	bnez	a0,80000728 <printf+0x17e>
    80000738:	bf39                	j	80000656 <printf+0xac>
        s = "(null)";
    8000073a:	00008497          	auipc	s1,0x8
    8000073e:	8de48493          	addi	s1,s1,-1826 # 80008018 <etext+0x18>
      for(; *s; s++)
    80000742:	02800513          	li	a0,40
    80000746:	b7cd                	j	80000728 <printf+0x17e>
      consputc('%');
    80000748:	855a                	mv	a0,s6
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	b4a080e7          	jalr	-1206(ra) # 80000294 <consputc>
      break;
    80000752:	b711                	j	80000656 <printf+0xac>
      consputc('%');
    80000754:	855a                	mv	a0,s6
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	b3e080e7          	jalr	-1218(ra) # 80000294 <consputc>
      consputc(c);
    8000075e:	8526                	mv	a0,s1
    80000760:	00000097          	auipc	ra,0x0
    80000764:	b34080e7          	jalr	-1228(ra) # 80000294 <consputc>
      break;
    80000768:	b5fd                	j	80000656 <printf+0xac>
    8000076a:	74a6                	ld	s1,104(sp)
    8000076c:	7906                	ld	s2,96(sp)
    8000076e:	69e6                	ld	s3,88(sp)
    80000770:	6aa6                	ld	s5,72(sp)
    80000772:	6b06                	ld	s6,64(sp)
    80000774:	7be2                	ld	s7,56(sp)
    80000776:	7c42                	ld	s8,48(sp)
    80000778:	7ca2                	ld	s9,40(sp)
    8000077a:	6de2                	ld	s11,24(sp)
  if(locking)
    8000077c:	020d1263          	bnez	s10,800007a0 <printf+0x1f6>
}
    80000780:	70e6                	ld	ra,120(sp)
    80000782:	7446                	ld	s0,112(sp)
    80000784:	6a46                	ld	s4,80(sp)
    80000786:	7d02                	ld	s10,32(sp)
    80000788:	6129                	addi	sp,sp,192
    8000078a:	8082                	ret
    8000078c:	74a6                	ld	s1,104(sp)
    8000078e:	7906                	ld	s2,96(sp)
    80000790:	69e6                	ld	s3,88(sp)
    80000792:	6aa6                	ld	s5,72(sp)
    80000794:	6b06                	ld	s6,64(sp)
    80000796:	7be2                	ld	s7,56(sp)
    80000798:	7c42                	ld	s8,48(sp)
    8000079a:	7ca2                	ld	s9,40(sp)
    8000079c:	6de2                	ld	s11,24(sp)
    8000079e:	bff9                	j	8000077c <printf+0x1d2>
    release(&pr.lock);
    800007a0:	00013517          	auipc	a0,0x13
    800007a4:	e0850513          	addi	a0,a0,-504 # 800135a8 <pr>
    800007a8:	00000097          	auipc	ra,0x0
    800007ac:	544080e7          	jalr	1348(ra) # 80000cec <release>
}
    800007b0:	bfc1                	j	80000780 <printf+0x1d6>

00000000800007b2 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007b2:	1101                	addi	sp,sp,-32
    800007b4:	ec06                	sd	ra,24(sp)
    800007b6:	e822                	sd	s0,16(sp)
    800007b8:	e426                	sd	s1,8(sp)
    800007ba:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800007bc:	00013497          	auipc	s1,0x13
    800007c0:	dec48493          	addi	s1,s1,-532 # 800135a8 <pr>
    800007c4:	00008597          	auipc	a1,0x8
    800007c8:	86c58593          	addi	a1,a1,-1940 # 80008030 <etext+0x30>
    800007cc:	8526                	mv	a0,s1
    800007ce:	00000097          	auipc	ra,0x0
    800007d2:	3da080e7          	jalr	986(ra) # 80000ba8 <initlock>
  pr.locking = 1;
    800007d6:	4785                	li	a5,1
    800007d8:	cc9c                	sw	a5,24(s1)
}
    800007da:	60e2                	ld	ra,24(sp)
    800007dc:	6442                	ld	s0,16(sp)
    800007de:	64a2                	ld	s1,8(sp)
    800007e0:	6105                	addi	sp,sp,32
    800007e2:	8082                	ret

00000000800007e4 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007e4:	1141                	addi	sp,sp,-16
    800007e6:	e406                	sd	ra,8(sp)
    800007e8:	e022                	sd	s0,0(sp)
    800007ea:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ec:	100007b7          	lui	a5,0x10000
    800007f0:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007f4:	10000737          	lui	a4,0x10000
    800007f8:	f8000693          	li	a3,-128
    800007fc:	00d701a3          	sb	a3,3(a4) # 10000003 <_entry-0x6ffffffd>

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000800:	468d                	li	a3,3
    80000802:	10000637          	lui	a2,0x10000
    80000806:	00d60023          	sb	a3,0(a2) # 10000000 <_entry-0x70000000>

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    8000080a:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000080e:	00d701a3          	sb	a3,3(a4)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000812:	10000737          	lui	a4,0x10000
    80000816:	461d                	li	a2,7
    80000818:	00c70123          	sb	a2,2(a4) # 10000002 <_entry-0x6ffffffe>

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    8000081c:	00d780a3          	sb	a3,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000820:	00008597          	auipc	a1,0x8
    80000824:	81858593          	addi	a1,a1,-2024 # 80008038 <etext+0x38>
    80000828:	00013517          	auipc	a0,0x13
    8000082c:	da050513          	addi	a0,a0,-608 # 800135c8 <uart_tx_lock>
    80000830:	00000097          	auipc	ra,0x0
    80000834:	378080e7          	jalr	888(ra) # 80000ba8 <initlock>
}
    80000838:	60a2                	ld	ra,8(sp)
    8000083a:	6402                	ld	s0,0(sp)
    8000083c:	0141                	addi	sp,sp,16
    8000083e:	8082                	ret

0000000080000840 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000840:	1101                	addi	sp,sp,-32
    80000842:	ec06                	sd	ra,24(sp)
    80000844:	e822                	sd	s0,16(sp)
    80000846:	e426                	sd	s1,8(sp)
    80000848:	1000                	addi	s0,sp,32
    8000084a:	84aa                	mv	s1,a0
  push_off();
    8000084c:	00000097          	auipc	ra,0x0
    80000850:	3a0080e7          	jalr	928(ra) # 80000bec <push_off>

  if(panicked){
    80000854:	0000b797          	auipc	a5,0xb
    80000858:	b2c7a783          	lw	a5,-1236(a5) # 8000b380 <panicked>
    8000085c:	eb85                	bnez	a5,8000088c <uartputc_sync+0x4c>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000085e:	10000737          	lui	a4,0x10000
    80000862:	0715                	addi	a4,a4,5 # 10000005 <_entry-0x6ffffffb>
    80000864:	00074783          	lbu	a5,0(a4)
    80000868:	0207f793          	andi	a5,a5,32
    8000086c:	dfe5                	beqz	a5,80000864 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000086e:	0ff4f513          	zext.b	a0,s1
    80000872:	100007b7          	lui	a5,0x10000
    80000876:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    8000087a:	00000097          	auipc	ra,0x0
    8000087e:	412080e7          	jalr	1042(ra) # 80000c8c <pop_off>
}
    80000882:	60e2                	ld	ra,24(sp)
    80000884:	6442                	ld	s0,16(sp)
    80000886:	64a2                	ld	s1,8(sp)
    80000888:	6105                	addi	sp,sp,32
    8000088a:	8082                	ret
    for(;;)
    8000088c:	a001                	j	8000088c <uartputc_sync+0x4c>

000000008000088e <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000088e:	0000b797          	auipc	a5,0xb
    80000892:	afa7b783          	ld	a5,-1286(a5) # 8000b388 <uart_tx_r>
    80000896:	0000b717          	auipc	a4,0xb
    8000089a:	afa73703          	ld	a4,-1286(a4) # 8000b390 <uart_tx_w>
    8000089e:	06f70f63          	beq	a4,a5,8000091c <uartstart+0x8e>
{
    800008a2:	7139                	addi	sp,sp,-64
    800008a4:	fc06                	sd	ra,56(sp)
    800008a6:	f822                	sd	s0,48(sp)
    800008a8:	f426                	sd	s1,40(sp)
    800008aa:	f04a                	sd	s2,32(sp)
    800008ac:	ec4e                	sd	s3,24(sp)
    800008ae:	e852                	sd	s4,16(sp)
    800008b0:	e456                	sd	s5,8(sp)
    800008b2:	e05a                	sd	s6,0(sp)
    800008b4:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008b6:	10000937          	lui	s2,0x10000
    800008ba:	0915                	addi	s2,s2,5 # 10000005 <_entry-0x6ffffffb>
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008bc:	00013a97          	auipc	s5,0x13
    800008c0:	d0ca8a93          	addi	s5,s5,-756 # 800135c8 <uart_tx_lock>
    uart_tx_r += 1;
    800008c4:	0000b497          	auipc	s1,0xb
    800008c8:	ac448493          	addi	s1,s1,-1340 # 8000b388 <uart_tx_r>
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    
    WriteReg(THR, c);
    800008cc:	10000a37          	lui	s4,0x10000
    if(uart_tx_w == uart_tx_r){
    800008d0:	0000b997          	auipc	s3,0xb
    800008d4:	ac098993          	addi	s3,s3,-1344 # 8000b390 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d8:	00094703          	lbu	a4,0(s2)
    800008dc:	02077713          	andi	a4,a4,32
    800008e0:	c705                	beqz	a4,80000908 <uartstart+0x7a>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008e2:	01f7f713          	andi	a4,a5,31
    800008e6:	9756                	add	a4,a4,s5
    800008e8:	01874b03          	lbu	s6,24(a4)
    uart_tx_r += 1;
    800008ec:	0785                	addi	a5,a5,1
    800008ee:	e09c                	sd	a5,0(s1)
    wakeup(&uart_tx_r);
    800008f0:	8526                	mv	a0,s1
    800008f2:	00002097          	auipc	ra,0x2
    800008f6:	a20080e7          	jalr	-1504(ra) # 80002312 <wakeup>
    WriteReg(THR, c);
    800008fa:	016a0023          	sb	s6,0(s4) # 10000000 <_entry-0x70000000>
    if(uart_tx_w == uart_tx_r){
    800008fe:	609c                	ld	a5,0(s1)
    80000900:	0009b703          	ld	a4,0(s3)
    80000904:	fcf71ae3          	bne	a4,a5,800008d8 <uartstart+0x4a>
  }
}
    80000908:	70e2                	ld	ra,56(sp)
    8000090a:	7442                	ld	s0,48(sp)
    8000090c:	74a2                	ld	s1,40(sp)
    8000090e:	7902                	ld	s2,32(sp)
    80000910:	69e2                	ld	s3,24(sp)
    80000912:	6a42                	ld	s4,16(sp)
    80000914:	6aa2                	ld	s5,8(sp)
    80000916:	6b02                	ld	s6,0(sp)
    80000918:	6121                	addi	sp,sp,64
    8000091a:	8082                	ret
    8000091c:	8082                	ret

000000008000091e <uartputc>:
{
    8000091e:	7179                	addi	sp,sp,-48
    80000920:	f406                	sd	ra,40(sp)
    80000922:	f022                	sd	s0,32(sp)
    80000924:	ec26                	sd	s1,24(sp)
    80000926:	e84a                	sd	s2,16(sp)
    80000928:	e44e                	sd	s3,8(sp)
    8000092a:	e052                	sd	s4,0(sp)
    8000092c:	1800                	addi	s0,sp,48
    8000092e:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    80000930:	00013517          	auipc	a0,0x13
    80000934:	c9850513          	addi	a0,a0,-872 # 800135c8 <uart_tx_lock>
    80000938:	00000097          	auipc	ra,0x0
    8000093c:	300080e7          	jalr	768(ra) # 80000c38 <acquire>
  if(panicked){
    80000940:	0000b797          	auipc	a5,0xb
    80000944:	a407a783          	lw	a5,-1472(a5) # 8000b380 <panicked>
    80000948:	e7c9                	bnez	a5,800009d2 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000094a:	0000b717          	auipc	a4,0xb
    8000094e:	a4673703          	ld	a4,-1466(a4) # 8000b390 <uart_tx_w>
    80000952:	0000b797          	auipc	a5,0xb
    80000956:	a367b783          	ld	a5,-1482(a5) # 8000b388 <uart_tx_r>
    8000095a:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000095e:	00013997          	auipc	s3,0x13
    80000962:	c6a98993          	addi	s3,s3,-918 # 800135c8 <uart_tx_lock>
    80000966:	0000b497          	auipc	s1,0xb
    8000096a:	a2248493          	addi	s1,s1,-1502 # 8000b388 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000096e:	0000b917          	auipc	s2,0xb
    80000972:	a2290913          	addi	s2,s2,-1502 # 8000b390 <uart_tx_w>
    80000976:	00e79f63          	bne	a5,a4,80000994 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000097a:	85ce                	mv	a1,s3
    8000097c:	8526                	mv	a0,s1
    8000097e:	00002097          	auipc	ra,0x2
    80000982:	930080e7          	jalr	-1744(ra) # 800022ae <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000986:	00093703          	ld	a4,0(s2)
    8000098a:	609c                	ld	a5,0(s1)
    8000098c:	02078793          	addi	a5,a5,32
    80000990:	fee785e3          	beq	a5,a4,8000097a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000994:	00013497          	auipc	s1,0x13
    80000998:	c3448493          	addi	s1,s1,-972 # 800135c8 <uart_tx_lock>
    8000099c:	01f77793          	andi	a5,a4,31
    800009a0:	97a6                	add	a5,a5,s1
    800009a2:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800009a6:	0705                	addi	a4,a4,1
    800009a8:	0000b797          	auipc	a5,0xb
    800009ac:	9ee7b423          	sd	a4,-1560(a5) # 8000b390 <uart_tx_w>
  uartstart();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	ede080e7          	jalr	-290(ra) # 8000088e <uartstart>
  release(&uart_tx_lock);
    800009b8:	8526                	mv	a0,s1
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	332080e7          	jalr	818(ra) # 80000cec <release>
}
    800009c2:	70a2                	ld	ra,40(sp)
    800009c4:	7402                	ld	s0,32(sp)
    800009c6:	64e2                	ld	s1,24(sp)
    800009c8:	6942                	ld	s2,16(sp)
    800009ca:	69a2                	ld	s3,8(sp)
    800009cc:	6a02                	ld	s4,0(sp)
    800009ce:	6145                	addi	sp,sp,48
    800009d0:	8082                	ret
    for(;;)
    800009d2:	a001                	j	800009d2 <uartputc+0xb4>

00000000800009d4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009d4:	1141                	addi	sp,sp,-16
    800009d6:	e422                	sd	s0,8(sp)
    800009d8:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009da:	100007b7          	lui	a5,0x10000
    800009de:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    800009e0:	0007c783          	lbu	a5,0(a5)
    800009e4:	8b85                	andi	a5,a5,1
    800009e6:	cb81                	beqz	a5,800009f6 <uartgetc+0x22>
    // input data is ready.
    return ReadReg(RHR);
    800009e8:	100007b7          	lui	a5,0x10000
    800009ec:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009f0:	6422                	ld	s0,8(sp)
    800009f2:	0141                	addi	sp,sp,16
    800009f4:	8082                	ret
    return -1;
    800009f6:	557d                	li	a0,-1
    800009f8:	bfe5                	j	800009f0 <uartgetc+0x1c>

00000000800009fa <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009fa:	1101                	addi	sp,sp,-32
    800009fc:	ec06                	sd	ra,24(sp)
    800009fe:	e822                	sd	s0,16(sp)
    80000a00:	e426                	sd	s1,8(sp)
    80000a02:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a04:	54fd                	li	s1,-1
    80000a06:	a029                	j	80000a10 <uartintr+0x16>
      break;
    consoleintr(c);
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	8ce080e7          	jalr	-1842(ra) # 800002d6 <consoleintr>
    int c = uartgetc();
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	fc4080e7          	jalr	-60(ra) # 800009d4 <uartgetc>
    if(c == -1)
    80000a18:	fe9518e3          	bne	a0,s1,80000a08 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a1c:	00013497          	auipc	s1,0x13
    80000a20:	bac48493          	addi	s1,s1,-1108 # 800135c8 <uart_tx_lock>
    80000a24:	8526                	mv	a0,s1
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	212080e7          	jalr	530(ra) # 80000c38 <acquire>
  uartstart();
    80000a2e:	00000097          	auipc	ra,0x0
    80000a32:	e60080e7          	jalr	-416(ra) # 8000088e <uartstart>
  release(&uart_tx_lock);
    80000a36:	8526                	mv	a0,s1
    80000a38:	00000097          	auipc	ra,0x0
    80000a3c:	2b4080e7          	jalr	692(ra) # 80000cec <release>
}
    80000a40:	60e2                	ld	ra,24(sp)
    80000a42:	6442                	ld	s0,16(sp)
    80000a44:	64a2                	ld	s1,8(sp)
    80000a46:	6105                	addi	sp,sp,32
    80000a48:	8082                	ret

0000000080000a4a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a4a:	1101                	addi	sp,sp,-32
    80000a4c:	ec06                	sd	ra,24(sp)
    80000a4e:	e822                	sd	s0,16(sp)
    80000a50:	e426                	sd	s1,8(sp)
    80000a52:	e04a                	sd	s2,0(sp)
    80000a54:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a56:	03451793          	slli	a5,a0,0x34
    80000a5a:	ebb9                	bnez	a5,80000ab0 <kfree+0x66>
    80000a5c:	84aa                	mv	s1,a0
    80000a5e:	00027797          	auipc	a5,0x27
    80000a62:	bd278793          	addi	a5,a5,-1070 # 80027630 <end>
    80000a66:	04f56563          	bltu	a0,a5,80000ab0 <kfree+0x66>
    80000a6a:	47c5                	li	a5,17
    80000a6c:	07ee                	slli	a5,a5,0x1b
    80000a6e:	04f57163          	bgeu	a0,a5,80000ab0 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a72:	6605                	lui	a2,0x1
    80000a74:	4585                	li	a1,1
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	2be080e7          	jalr	702(ra) # 80000d34 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a7e:	00013917          	auipc	s2,0x13
    80000a82:	b8290913          	addi	s2,s2,-1150 # 80013600 <kmem>
    80000a86:	854a                	mv	a0,s2
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	1b0080e7          	jalr	432(ra) # 80000c38 <acquire>
  r->next = kmem.freelist;
    80000a90:	01893783          	ld	a5,24(s2)
    80000a94:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a96:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a9a:	854a                	mv	a0,s2
    80000a9c:	00000097          	auipc	ra,0x0
    80000aa0:	250080e7          	jalr	592(ra) # 80000cec <release>
}
    80000aa4:	60e2                	ld	ra,24(sp)
    80000aa6:	6442                	ld	s0,16(sp)
    80000aa8:	64a2                	ld	s1,8(sp)
    80000aaa:	6902                	ld	s2,0(sp)
    80000aac:	6105                	addi	sp,sp,32
    80000aae:	8082                	ret
    panic("kfree");
    80000ab0:	00007517          	auipc	a0,0x7
    80000ab4:	59050513          	addi	a0,a0,1424 # 80008040 <etext+0x40>
    80000ab8:	00000097          	auipc	ra,0x0
    80000abc:	aa8080e7          	jalr	-1368(ra) # 80000560 <panic>

0000000080000ac0 <freerange>:
{
    80000ac0:	7179                	addi	sp,sp,-48
    80000ac2:	f406                	sd	ra,40(sp)
    80000ac4:	f022                	sd	s0,32(sp)
    80000ac6:	ec26                	sd	s1,24(sp)
    80000ac8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aca:	6785                	lui	a5,0x1
    80000acc:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ad0:	00e504b3          	add	s1,a0,a4
    80000ad4:	777d                	lui	a4,0xfffff
    80000ad6:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ad8:	94be                	add	s1,s1,a5
    80000ada:	0295e463          	bltu	a1,s1,80000b02 <freerange+0x42>
    80000ade:	e84a                	sd	s2,16(sp)
    80000ae0:	e44e                	sd	s3,8(sp)
    80000ae2:	e052                	sd	s4,0(sp)
    80000ae4:	892e                	mv	s2,a1
    kfree(p);
    80000ae6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ae8:	6985                	lui	s3,0x1
    kfree(p);
    80000aea:	01448533          	add	a0,s1,s4
    80000aee:	00000097          	auipc	ra,0x0
    80000af2:	f5c080e7          	jalr	-164(ra) # 80000a4a <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af6:	94ce                	add	s1,s1,s3
    80000af8:	fe9979e3          	bgeu	s2,s1,80000aea <freerange+0x2a>
    80000afc:	6942                	ld	s2,16(sp)
    80000afe:	69a2                	ld	s3,8(sp)
    80000b00:	6a02                	ld	s4,0(sp)
}
    80000b02:	70a2                	ld	ra,40(sp)
    80000b04:	7402                	ld	s0,32(sp)
    80000b06:	64e2                	ld	s1,24(sp)
    80000b08:	6145                	addi	sp,sp,48
    80000b0a:	8082                	ret

0000000080000b0c <kinit>:
{
    80000b0c:	1141                	addi	sp,sp,-16
    80000b0e:	e406                	sd	ra,8(sp)
    80000b10:	e022                	sd	s0,0(sp)
    80000b12:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b14:	00007597          	auipc	a1,0x7
    80000b18:	53458593          	addi	a1,a1,1332 # 80008048 <etext+0x48>
    80000b1c:	00013517          	auipc	a0,0x13
    80000b20:	ae450513          	addi	a0,a0,-1308 # 80013600 <kmem>
    80000b24:	00000097          	auipc	ra,0x0
    80000b28:	084080e7          	jalr	132(ra) # 80000ba8 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b2c:	45c5                	li	a1,17
    80000b2e:	05ee                	slli	a1,a1,0x1b
    80000b30:	00027517          	auipc	a0,0x27
    80000b34:	b0050513          	addi	a0,a0,-1280 # 80027630 <end>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	f88080e7          	jalr	-120(ra) # 80000ac0 <freerange>
}
    80000b40:	60a2                	ld	ra,8(sp)
    80000b42:	6402                	ld	s0,0(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b48:	1101                	addi	sp,sp,-32
    80000b4a:	ec06                	sd	ra,24(sp)
    80000b4c:	e822                	sd	s0,16(sp)
    80000b4e:	e426                	sd	s1,8(sp)
    80000b50:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b52:	00013497          	auipc	s1,0x13
    80000b56:	aae48493          	addi	s1,s1,-1362 # 80013600 <kmem>
    80000b5a:	8526                	mv	a0,s1
    80000b5c:	00000097          	auipc	ra,0x0
    80000b60:	0dc080e7          	jalr	220(ra) # 80000c38 <acquire>
  r = kmem.freelist;
    80000b64:	6c84                	ld	s1,24(s1)
  if(r)
    80000b66:	c885                	beqz	s1,80000b96 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b68:	609c                	ld	a5,0(s1)
    80000b6a:	00013517          	auipc	a0,0x13
    80000b6e:	a9650513          	addi	a0,a0,-1386 # 80013600 <kmem>
    80000b72:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b74:	00000097          	auipc	ra,0x0
    80000b78:	178080e7          	jalr	376(ra) # 80000cec <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b7c:	6605                	lui	a2,0x1
    80000b7e:	4595                	li	a1,5
    80000b80:	8526                	mv	a0,s1
    80000b82:	00000097          	auipc	ra,0x0
    80000b86:	1b2080e7          	jalr	434(ra) # 80000d34 <memset>
  return (void*)r;
}
    80000b8a:	8526                	mv	a0,s1
    80000b8c:	60e2                	ld	ra,24(sp)
    80000b8e:	6442                	ld	s0,16(sp)
    80000b90:	64a2                	ld	s1,8(sp)
    80000b92:	6105                	addi	sp,sp,32
    80000b94:	8082                	ret
  release(&kmem.lock);
    80000b96:	00013517          	auipc	a0,0x13
    80000b9a:	a6a50513          	addi	a0,a0,-1430 # 80013600 <kmem>
    80000b9e:	00000097          	auipc	ra,0x0
    80000ba2:	14e080e7          	jalr	334(ra) # 80000cec <release>
  if(r)
    80000ba6:	b7d5                	j	80000b8a <kalloc+0x42>

0000000080000ba8 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000ba8:	1141                	addi	sp,sp,-16
    80000baa:	e422                	sd	s0,8(sp)
    80000bac:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bae:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bb0:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bb4:	00053823          	sd	zero,16(a0)
}
    80000bb8:	6422                	ld	s0,8(sp)
    80000bba:	0141                	addi	sp,sp,16
    80000bbc:	8082                	ret

0000000080000bbe <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bbe:	411c                	lw	a5,0(a0)
    80000bc0:	e399                	bnez	a5,80000bc6 <holding+0x8>
    80000bc2:	4501                	li	a0,0
  return r;
}
    80000bc4:	8082                	ret
{
    80000bc6:	1101                	addi	sp,sp,-32
    80000bc8:	ec06                	sd	ra,24(sp)
    80000bca:	e822                	sd	s0,16(sp)
    80000bcc:	e426                	sd	s1,8(sp)
    80000bce:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bd0:	6904                	ld	s1,16(a0)
    80000bd2:	00001097          	auipc	ra,0x1
    80000bd6:	e5c080e7          	jalr	-420(ra) # 80001a2e <mycpu>
    80000bda:	40a48533          	sub	a0,s1,a0
    80000bde:	00153513          	seqz	a0,a0
}
    80000be2:	60e2                	ld	ra,24(sp)
    80000be4:	6442                	ld	s0,16(sp)
    80000be6:	64a2                	ld	s1,8(sp)
    80000be8:	6105                	addi	sp,sp,32
    80000bea:	8082                	ret

0000000080000bec <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bec:	1101                	addi	sp,sp,-32
    80000bee:	ec06                	sd	ra,24(sp)
    80000bf0:	e822                	sd	s0,16(sp)
    80000bf2:	e426                	sd	s1,8(sp)
    80000bf4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bf6:	100024f3          	csrr	s1,sstatus
    80000bfa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bfe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c00:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c04:	00001097          	auipc	ra,0x1
    80000c08:	e2a080e7          	jalr	-470(ra) # 80001a2e <mycpu>
    80000c0c:	5d3c                	lw	a5,120(a0)
    80000c0e:	cf89                	beqz	a5,80000c28 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c10:	00001097          	auipc	ra,0x1
    80000c14:	e1e080e7          	jalr	-482(ra) # 80001a2e <mycpu>
    80000c18:	5d3c                	lw	a5,120(a0)
    80000c1a:	2785                	addiw	a5,a5,1
    80000c1c:	dd3c                	sw	a5,120(a0)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    mycpu()->intena = old;
    80000c28:	00001097          	auipc	ra,0x1
    80000c2c:	e06080e7          	jalr	-506(ra) # 80001a2e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c30:	8085                	srli	s1,s1,0x1
    80000c32:	8885                	andi	s1,s1,1
    80000c34:	dd64                	sw	s1,124(a0)
    80000c36:	bfe9                	j	80000c10 <push_off+0x24>

0000000080000c38 <acquire>:
{
    80000c38:	1101                	addi	sp,sp,-32
    80000c3a:	ec06                	sd	ra,24(sp)
    80000c3c:	e822                	sd	s0,16(sp)
    80000c3e:	e426                	sd	s1,8(sp)
    80000c40:	1000                	addi	s0,sp,32
    80000c42:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c44:	00000097          	auipc	ra,0x0
    80000c48:	fa8080e7          	jalr	-88(ra) # 80000bec <push_off>
  if(holding(lk))
    80000c4c:	8526                	mv	a0,s1
    80000c4e:	00000097          	auipc	ra,0x0
    80000c52:	f70080e7          	jalr	-144(ra) # 80000bbe <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c56:	4705                	li	a4,1
  if(holding(lk))
    80000c58:	e115                	bnez	a0,80000c7c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c5a:	87ba                	mv	a5,a4
    80000c5c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c60:	2781                	sext.w	a5,a5
    80000c62:	ffe5                	bnez	a5,80000c5a <acquire+0x22>
  __sync_synchronize();
    80000c64:	0330000f          	fence	rw,rw
  lk->cpu = mycpu();
    80000c68:	00001097          	auipc	ra,0x1
    80000c6c:	dc6080e7          	jalr	-570(ra) # 80001a2e <mycpu>
    80000c70:	e888                	sd	a0,16(s1)
}
    80000c72:	60e2                	ld	ra,24(sp)
    80000c74:	6442                	ld	s0,16(sp)
    80000c76:	64a2                	ld	s1,8(sp)
    80000c78:	6105                	addi	sp,sp,32
    80000c7a:	8082                	ret
    panic("acquire");
    80000c7c:	00007517          	auipc	a0,0x7
    80000c80:	3d450513          	addi	a0,a0,980 # 80008050 <etext+0x50>
    80000c84:	00000097          	auipc	ra,0x0
    80000c88:	8dc080e7          	jalr	-1828(ra) # 80000560 <panic>

0000000080000c8c <pop_off>:

void
pop_off(void)
{
    80000c8c:	1141                	addi	sp,sp,-16
    80000c8e:	e406                	sd	ra,8(sp)
    80000c90:	e022                	sd	s0,0(sp)
    80000c92:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c94:	00001097          	auipc	ra,0x1
    80000c98:	d9a080e7          	jalr	-614(ra) # 80001a2e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c9c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000ca0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000ca2:	e78d                	bnez	a5,80000ccc <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000ca4:	5d3c                	lw	a5,120(a0)
    80000ca6:	02f05b63          	blez	a5,80000cdc <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000caa:	37fd                	addiw	a5,a5,-1
    80000cac:	0007871b          	sext.w	a4,a5
    80000cb0:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cb2:	eb09                	bnez	a4,80000cc4 <pop_off+0x38>
    80000cb4:	5d7c                	lw	a5,124(a0)
    80000cb6:	c799                	beqz	a5,80000cc4 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cbc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cc0:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cc4:	60a2                	ld	ra,8(sp)
    80000cc6:	6402                	ld	s0,0(sp)
    80000cc8:	0141                	addi	sp,sp,16
    80000cca:	8082                	ret
    panic("pop_off - interruptible");
    80000ccc:	00007517          	auipc	a0,0x7
    80000cd0:	38c50513          	addi	a0,a0,908 # 80008058 <etext+0x58>
    80000cd4:	00000097          	auipc	ra,0x0
    80000cd8:	88c080e7          	jalr	-1908(ra) # 80000560 <panic>
    panic("pop_off");
    80000cdc:	00007517          	auipc	a0,0x7
    80000ce0:	39450513          	addi	a0,a0,916 # 80008070 <etext+0x70>
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	87c080e7          	jalr	-1924(ra) # 80000560 <panic>

0000000080000cec <release>:
{
    80000cec:	1101                	addi	sp,sp,-32
    80000cee:	ec06                	sd	ra,24(sp)
    80000cf0:	e822                	sd	s0,16(sp)
    80000cf2:	e426                	sd	s1,8(sp)
    80000cf4:	1000                	addi	s0,sp,32
    80000cf6:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cf8:	00000097          	auipc	ra,0x0
    80000cfc:	ec6080e7          	jalr	-314(ra) # 80000bbe <holding>
    80000d00:	c115                	beqz	a0,80000d24 <release+0x38>
  lk->cpu = 0;
    80000d02:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d06:	0330000f          	fence	rw,rw
  __sync_lock_release(&lk->locked);
    80000d0a:	0310000f          	fence	rw,w
    80000d0e:	0004a023          	sw	zero,0(s1)
  pop_off();
    80000d12:	00000097          	auipc	ra,0x0
    80000d16:	f7a080e7          	jalr	-134(ra) # 80000c8c <pop_off>
}
    80000d1a:	60e2                	ld	ra,24(sp)
    80000d1c:	6442                	ld	s0,16(sp)
    80000d1e:	64a2                	ld	s1,8(sp)
    80000d20:	6105                	addi	sp,sp,32
    80000d22:	8082                	ret
    panic("release");
    80000d24:	00007517          	auipc	a0,0x7
    80000d28:	35450513          	addi	a0,a0,852 # 80008078 <etext+0x78>
    80000d2c:	00000097          	auipc	ra,0x0
    80000d30:	834080e7          	jalr	-1996(ra) # 80000560 <panic>

0000000080000d34 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d34:	1141                	addi	sp,sp,-16
    80000d36:	e422                	sd	s0,8(sp)
    80000d38:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d3a:	ca19                	beqz	a2,80000d50 <memset+0x1c>
    80000d3c:	87aa                	mv	a5,a0
    80000d3e:	1602                	slli	a2,a2,0x20
    80000d40:	9201                	srli	a2,a2,0x20
    80000d42:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d46:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d4a:	0785                	addi	a5,a5,1
    80000d4c:	fee79de3          	bne	a5,a4,80000d46 <memset+0x12>
  }
  return dst;
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	addi	sp,sp,16
    80000d54:	8082                	ret

0000000080000d56 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d5c:	ca05                	beqz	a2,80000d8c <memcmp+0x36>
    80000d5e:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d62:	1682                	slli	a3,a3,0x20
    80000d64:	9281                	srli	a3,a3,0x20
    80000d66:	0685                	addi	a3,a3,1
    80000d68:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d6a:	00054783          	lbu	a5,0(a0)
    80000d6e:	0005c703          	lbu	a4,0(a1)
    80000d72:	00e79863          	bne	a5,a4,80000d82 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d76:	0505                	addi	a0,a0,1
    80000d78:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d7a:	fed518e3          	bne	a0,a3,80000d6a <memcmp+0x14>
  }

  return 0;
    80000d7e:	4501                	li	a0,0
    80000d80:	a019                	j	80000d86 <memcmp+0x30>
      return *s1 - *s2;
    80000d82:	40e7853b          	subw	a0,a5,a4
}
    80000d86:	6422                	ld	s0,8(sp)
    80000d88:	0141                	addi	sp,sp,16
    80000d8a:	8082                	ret
  return 0;
    80000d8c:	4501                	li	a0,0
    80000d8e:	bfe5                	j	80000d86 <memcmp+0x30>

0000000080000d90 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d90:	1141                	addi	sp,sp,-16
    80000d92:	e422                	sd	s0,8(sp)
    80000d94:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d96:	c205                	beqz	a2,80000db6 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d98:	02a5e263          	bltu	a1,a0,80000dbc <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d9c:	1602                	slli	a2,a2,0x20
    80000d9e:	9201                	srli	a2,a2,0x20
    80000da0:	00c587b3          	add	a5,a1,a2
{
    80000da4:	872a                	mv	a4,a0
      *d++ = *s++;
    80000da6:	0585                	addi	a1,a1,1
    80000da8:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd79d1>
    80000daa:	fff5c683          	lbu	a3,-1(a1)
    80000dae:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000db2:	feb79ae3          	bne	a5,a1,80000da6 <memmove+0x16>

  return dst;
}
    80000db6:	6422                	ld	s0,8(sp)
    80000db8:	0141                	addi	sp,sp,16
    80000dba:	8082                	ret
  if(s < d && s + n > d){
    80000dbc:	02061693          	slli	a3,a2,0x20
    80000dc0:	9281                	srli	a3,a3,0x20
    80000dc2:	00d58733          	add	a4,a1,a3
    80000dc6:	fce57be3          	bgeu	a0,a4,80000d9c <memmove+0xc>
    d += n;
    80000dca:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000dcc:	fff6079b          	addiw	a5,a2,-1
    80000dd0:	1782                	slli	a5,a5,0x20
    80000dd2:	9381                	srli	a5,a5,0x20
    80000dd4:	fff7c793          	not	a5,a5
    80000dd8:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dda:	177d                	addi	a4,a4,-1
    80000ddc:	16fd                	addi	a3,a3,-1
    80000dde:	00074603          	lbu	a2,0(a4)
    80000de2:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000de6:	fef71ae3          	bne	a4,a5,80000dda <memmove+0x4a>
    80000dea:	b7f1                	j	80000db6 <memmove+0x26>

0000000080000dec <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dec:	1141                	addi	sp,sp,-16
    80000dee:	e406                	sd	ra,8(sp)
    80000df0:	e022                	sd	s0,0(sp)
    80000df2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000df4:	00000097          	auipc	ra,0x0
    80000df8:	f9c080e7          	jalr	-100(ra) # 80000d90 <memmove>
}
    80000dfc:	60a2                	ld	ra,8(sp)
    80000dfe:	6402                	ld	s0,0(sp)
    80000e00:	0141                	addi	sp,sp,16
    80000e02:	8082                	ret

0000000080000e04 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e04:	1141                	addi	sp,sp,-16
    80000e06:	e422                	sd	s0,8(sp)
    80000e08:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e0a:	ce11                	beqz	a2,80000e26 <strncmp+0x22>
    80000e0c:	00054783          	lbu	a5,0(a0)
    80000e10:	cf89                	beqz	a5,80000e2a <strncmp+0x26>
    80000e12:	0005c703          	lbu	a4,0(a1)
    80000e16:	00f71a63          	bne	a4,a5,80000e2a <strncmp+0x26>
    n--, p++, q++;
    80000e1a:	367d                	addiw	a2,a2,-1
    80000e1c:	0505                	addi	a0,a0,1
    80000e1e:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e20:	f675                	bnez	a2,80000e0c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e22:	4501                	li	a0,0
    80000e24:	a801                	j	80000e34 <strncmp+0x30>
    80000e26:	4501                	li	a0,0
    80000e28:	a031                	j	80000e34 <strncmp+0x30>
  return (uchar)*p - (uchar)*q;
    80000e2a:	00054503          	lbu	a0,0(a0)
    80000e2e:	0005c783          	lbu	a5,0(a1)
    80000e32:	9d1d                	subw	a0,a0,a5
}
    80000e34:	6422                	ld	s0,8(sp)
    80000e36:	0141                	addi	sp,sp,16
    80000e38:	8082                	ret

0000000080000e3a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e3a:	1141                	addi	sp,sp,-16
    80000e3c:	e422                	sd	s0,8(sp)
    80000e3e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e40:	87aa                	mv	a5,a0
    80000e42:	86b2                	mv	a3,a2
    80000e44:	367d                	addiw	a2,a2,-1
    80000e46:	02d05563          	blez	a3,80000e70 <strncpy+0x36>
    80000e4a:	0785                	addi	a5,a5,1
    80000e4c:	0005c703          	lbu	a4,0(a1)
    80000e50:	fee78fa3          	sb	a4,-1(a5)
    80000e54:	0585                	addi	a1,a1,1
    80000e56:	f775                	bnez	a4,80000e42 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e58:	873e                	mv	a4,a5
    80000e5a:	9fb5                	addw	a5,a5,a3
    80000e5c:	37fd                	addiw	a5,a5,-1
    80000e5e:	00c05963          	blez	a2,80000e70 <strncpy+0x36>
    *s++ = 0;
    80000e62:	0705                	addi	a4,a4,1
    80000e64:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e68:	40e786bb          	subw	a3,a5,a4
    80000e6c:	fed04be3          	bgtz	a3,80000e62 <strncpy+0x28>
  return os;
}
    80000e70:	6422                	ld	s0,8(sp)
    80000e72:	0141                	addi	sp,sp,16
    80000e74:	8082                	ret

0000000080000e76 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e76:	1141                	addi	sp,sp,-16
    80000e78:	e422                	sd	s0,8(sp)
    80000e7a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e7c:	02c05363          	blez	a2,80000ea2 <safestrcpy+0x2c>
    80000e80:	fff6069b          	addiw	a3,a2,-1
    80000e84:	1682                	slli	a3,a3,0x20
    80000e86:	9281                	srli	a3,a3,0x20
    80000e88:	96ae                	add	a3,a3,a1
    80000e8a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e8c:	00d58963          	beq	a1,a3,80000e9e <safestrcpy+0x28>
    80000e90:	0585                	addi	a1,a1,1
    80000e92:	0785                	addi	a5,a5,1
    80000e94:	fff5c703          	lbu	a4,-1(a1)
    80000e98:	fee78fa3          	sb	a4,-1(a5)
    80000e9c:	fb65                	bnez	a4,80000e8c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e9e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ea2:	6422                	ld	s0,8(sp)
    80000ea4:	0141                	addi	sp,sp,16
    80000ea6:	8082                	ret

0000000080000ea8 <strlen>:

int
strlen(const char *s)
{
    80000ea8:	1141                	addi	sp,sp,-16
    80000eaa:	e422                	sd	s0,8(sp)
    80000eac:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000eae:	00054783          	lbu	a5,0(a0)
    80000eb2:	cf91                	beqz	a5,80000ece <strlen+0x26>
    80000eb4:	0505                	addi	a0,a0,1
    80000eb6:	87aa                	mv	a5,a0
    80000eb8:	86be                	mv	a3,a5
    80000eba:	0785                	addi	a5,a5,1
    80000ebc:	fff7c703          	lbu	a4,-1(a5)
    80000ec0:	ff65                	bnez	a4,80000eb8 <strlen+0x10>
    80000ec2:	40a6853b          	subw	a0,a3,a0
    80000ec6:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000ec8:	6422                	ld	s0,8(sp)
    80000eca:	0141                	addi	sp,sp,16
    80000ecc:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ece:	4501                	li	a0,0
    80000ed0:	bfe5                	j	80000ec8 <strlen+0x20>

0000000080000ed2 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ed2:	1141                	addi	sp,sp,-16
    80000ed4:	e406                	sd	ra,8(sp)
    80000ed6:	e022                	sd	s0,0(sp)
    80000ed8:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	b44080e7          	jalr	-1212(ra) # 80001a1e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ee2:	0000a717          	auipc	a4,0xa
    80000ee6:	4b670713          	addi	a4,a4,1206 # 8000b398 <started>
  if(cpuid() == 0){
    80000eea:	c139                	beqz	a0,80000f30 <main+0x5e>
    while(started == 0)
    80000eec:	431c                	lw	a5,0(a4)
    80000eee:	2781                	sext.w	a5,a5
    80000ef0:	dff5                	beqz	a5,80000eec <main+0x1a>
      ;
    __sync_synchronize();
    80000ef2:	0330000f          	fence	rw,rw
    printf("hart %d starting\n", cpuid());
    80000ef6:	00001097          	auipc	ra,0x1
    80000efa:	b28080e7          	jalr	-1240(ra) # 80001a1e <cpuid>
    80000efe:	85aa                	mv	a1,a0
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	19850513          	addi	a0,a0,408 # 80008098 <etext+0x98>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	6a2080e7          	jalr	1698(ra) # 800005aa <printf>
    kvminithart();    // turn on paging
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	0d8080e7          	jalr	216(ra) # 80000fe8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f18:	00002097          	auipc	ra,0x2
    80000f1c:	bd8080e7          	jalr	-1064(ra) # 80002af0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f20:	00005097          	auipc	ra,0x5
    80000f24:	454080e7          	jalr	1108(ra) # 80006374 <plicinithart>
  }

  scheduler();        
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	0c4080e7          	jalr	196(ra) # 80001fec <scheduler>
    consoleinit();
    80000f30:	fffff097          	auipc	ra,0xfffff
    80000f34:	540080e7          	jalr	1344(ra) # 80000470 <consoleinit>
    printfinit();
    80000f38:	00000097          	auipc	ra,0x0
    80000f3c:	87a080e7          	jalr	-1926(ra) # 800007b2 <printfinit>
    printf("\n");
    80000f40:	00007517          	auipc	a0,0x7
    80000f44:	0d050513          	addi	a0,a0,208 # 80008010 <etext+0x10>
    80000f48:	fffff097          	auipc	ra,0xfffff
    80000f4c:	662080e7          	jalr	1634(ra) # 800005aa <printf>
    printf("xv6 kernel is booting\n");
    80000f50:	00007517          	auipc	a0,0x7
    80000f54:	13050513          	addi	a0,a0,304 # 80008080 <etext+0x80>
    80000f58:	fffff097          	auipc	ra,0xfffff
    80000f5c:	652080e7          	jalr	1618(ra) # 800005aa <printf>
    printf("\n");
    80000f60:	00007517          	auipc	a0,0x7
    80000f64:	0b050513          	addi	a0,a0,176 # 80008010 <etext+0x10>
    80000f68:	fffff097          	auipc	ra,0xfffff
    80000f6c:	642080e7          	jalr	1602(ra) # 800005aa <printf>
    kinit();         // physical page allocator
    80000f70:	00000097          	auipc	ra,0x0
    80000f74:	b9c080e7          	jalr	-1124(ra) # 80000b0c <kinit>
    kvminit();       // create kernel page table
    80000f78:	00000097          	auipc	ra,0x0
    80000f7c:	326080e7          	jalr	806(ra) # 8000129e <kvminit>
    kvminithart();   // turn on paging
    80000f80:	00000097          	auipc	ra,0x0
    80000f84:	068080e7          	jalr	104(ra) # 80000fe8 <kvminithart>
    procinit();      // process table
    80000f88:	00001097          	auipc	ra,0x1
    80000f8c:	9d4080e7          	jalr	-1580(ra) # 8000195c <procinit>
    trapinit();      // trap vectors
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	b38080e7          	jalr	-1224(ra) # 80002ac8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f98:	00002097          	auipc	ra,0x2
    80000f9c:	b58080e7          	jalr	-1192(ra) # 80002af0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fa0:	00005097          	auipc	ra,0x5
    80000fa4:	3ba080e7          	jalr	954(ra) # 8000635a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fa8:	00005097          	auipc	ra,0x5
    80000fac:	3cc080e7          	jalr	972(ra) # 80006374 <plicinithart>
    binit();         // buffer cache
    80000fb0:	00002097          	auipc	ra,0x2
    80000fb4:	49a080e7          	jalr	1178(ra) # 8000344a <binit>
    iinit();         // inode table
    80000fb8:	00003097          	auipc	ra,0x3
    80000fbc:	b50080e7          	jalr	-1200(ra) # 80003b08 <iinit>
    fileinit();      // file table
    80000fc0:	00004097          	auipc	ra,0x4
    80000fc4:	b00080e7          	jalr	-1280(ra) # 80004ac0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fc8:	00005097          	auipc	ra,0x5
    80000fcc:	4b4080e7          	jalr	1204(ra) # 8000647c <virtio_disk_init>
    userinit();      // first user process
    80000fd0:	00001097          	auipc	ra,0x1
    80000fd4:	db8080e7          	jalr	-584(ra) # 80001d88 <userinit>
    __sync_synchronize();
    80000fd8:	0330000f          	fence	rw,rw
    started = 1;
    80000fdc:	4785                	li	a5,1
    80000fde:	0000a717          	auipc	a4,0xa
    80000fe2:	3af72d23          	sw	a5,954(a4) # 8000b398 <started>
    80000fe6:	b789                	j	80000f28 <main+0x56>

0000000080000fe8 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fe8:	1141                	addi	sp,sp,-16
    80000fea:	e422                	sd	s0,8(sp)
    80000fec:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fee:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000ff2:	0000a797          	auipc	a5,0xa
    80000ff6:	3ae7b783          	ld	a5,942(a5) # 8000b3a0 <kernel_pagetable>
    80000ffa:	83b1                	srli	a5,a5,0xc
    80000ffc:	577d                	li	a4,-1
    80000ffe:	177e                	slli	a4,a4,0x3f
    80001000:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001002:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001006:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    8000100a:	6422                	ld	s0,8(sp)
    8000100c:	0141                	addi	sp,sp,16
    8000100e:	8082                	ret

0000000080001010 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001010:	7139                	addi	sp,sp,-64
    80001012:	fc06                	sd	ra,56(sp)
    80001014:	f822                	sd	s0,48(sp)
    80001016:	f426                	sd	s1,40(sp)
    80001018:	f04a                	sd	s2,32(sp)
    8000101a:	ec4e                	sd	s3,24(sp)
    8000101c:	e852                	sd	s4,16(sp)
    8000101e:	e456                	sd	s5,8(sp)
    80001020:	e05a                	sd	s6,0(sp)
    80001022:	0080                	addi	s0,sp,64
    80001024:	84aa                	mv	s1,a0
    80001026:	89ae                	mv	s3,a1
    80001028:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000102a:	57fd                	li	a5,-1
    8000102c:	83e9                	srli	a5,a5,0x1a
    8000102e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001030:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001032:	04b7f263          	bgeu	a5,a1,80001076 <walk+0x66>
    panic("walk");
    80001036:	00007517          	auipc	a0,0x7
    8000103a:	07a50513          	addi	a0,a0,122 # 800080b0 <etext+0xb0>
    8000103e:	fffff097          	auipc	ra,0xfffff
    80001042:	522080e7          	jalr	1314(ra) # 80000560 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001046:	060a8663          	beqz	s5,800010b2 <walk+0xa2>
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	afe080e7          	jalr	-1282(ra) # 80000b48 <kalloc>
    80001052:	84aa                	mv	s1,a0
    80001054:	c529                	beqz	a0,8000109e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001056:	6605                	lui	a2,0x1
    80001058:	4581                	li	a1,0
    8000105a:	00000097          	auipc	ra,0x0
    8000105e:	cda080e7          	jalr	-806(ra) # 80000d34 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001062:	00c4d793          	srli	a5,s1,0xc
    80001066:	07aa                	slli	a5,a5,0xa
    80001068:	0017e793          	ori	a5,a5,1
    8000106c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001070:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd79c7>
    80001072:	036a0063          	beq	s4,s6,80001092 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001076:	0149d933          	srl	s2,s3,s4
    8000107a:	1ff97913          	andi	s2,s2,511
    8000107e:	090e                	slli	s2,s2,0x3
    80001080:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001082:	00093483          	ld	s1,0(s2)
    80001086:	0014f793          	andi	a5,s1,1
    8000108a:	dfd5                	beqz	a5,80001046 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000108c:	80a9                	srli	s1,s1,0xa
    8000108e:	04b2                	slli	s1,s1,0xc
    80001090:	b7c5                	j	80001070 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001092:	00c9d513          	srli	a0,s3,0xc
    80001096:	1ff57513          	andi	a0,a0,511
    8000109a:	050e                	slli	a0,a0,0x3
    8000109c:	9526                	add	a0,a0,s1
}
    8000109e:	70e2                	ld	ra,56(sp)
    800010a0:	7442                	ld	s0,48(sp)
    800010a2:	74a2                	ld	s1,40(sp)
    800010a4:	7902                	ld	s2,32(sp)
    800010a6:	69e2                	ld	s3,24(sp)
    800010a8:	6a42                	ld	s4,16(sp)
    800010aa:	6aa2                	ld	s5,8(sp)
    800010ac:	6b02                	ld	s6,0(sp)
    800010ae:	6121                	addi	sp,sp,64
    800010b0:	8082                	ret
        return 0;
    800010b2:	4501                	li	a0,0
    800010b4:	b7ed                	j	8000109e <walk+0x8e>

00000000800010b6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010b6:	57fd                	li	a5,-1
    800010b8:	83e9                	srli	a5,a5,0x1a
    800010ba:	00b7f463          	bgeu	a5,a1,800010c2 <walkaddr+0xc>
    return 0;
    800010be:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010c0:	8082                	ret
{
    800010c2:	1141                	addi	sp,sp,-16
    800010c4:	e406                	sd	ra,8(sp)
    800010c6:	e022                	sd	s0,0(sp)
    800010c8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ca:	4601                	li	a2,0
    800010cc:	00000097          	auipc	ra,0x0
    800010d0:	f44080e7          	jalr	-188(ra) # 80001010 <walk>
  if(pte == 0)
    800010d4:	c105                	beqz	a0,800010f4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010d6:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010d8:	0117f693          	andi	a3,a5,17
    800010dc:	4745                	li	a4,17
    return 0;
    800010de:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010e0:	00e68663          	beq	a3,a4,800010ec <walkaddr+0x36>
}
    800010e4:	60a2                	ld	ra,8(sp)
    800010e6:	6402                	ld	s0,0(sp)
    800010e8:	0141                	addi	sp,sp,16
    800010ea:	8082                	ret
  pa = PTE2PA(*pte);
    800010ec:	83a9                	srli	a5,a5,0xa
    800010ee:	00c79513          	slli	a0,a5,0xc
  return pa;
    800010f2:	bfcd                	j	800010e4 <walkaddr+0x2e>
    return 0;
    800010f4:	4501                	li	a0,0
    800010f6:	b7fd                	j	800010e4 <walkaddr+0x2e>

00000000800010f8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010f8:	715d                	addi	sp,sp,-80
    800010fa:	e486                	sd	ra,72(sp)
    800010fc:	e0a2                	sd	s0,64(sp)
    800010fe:	fc26                	sd	s1,56(sp)
    80001100:	f84a                	sd	s2,48(sp)
    80001102:	f44e                	sd	s3,40(sp)
    80001104:	f052                	sd	s4,32(sp)
    80001106:	ec56                	sd	s5,24(sp)
    80001108:	e85a                	sd	s6,16(sp)
    8000110a:	e45e                	sd	s7,8(sp)
    8000110c:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000110e:	c639                	beqz	a2,8000115c <mappages+0x64>
    80001110:	8aaa                	mv	s5,a0
    80001112:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001114:	777d                	lui	a4,0xfffff
    80001116:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000111a:	fff58993          	addi	s3,a1,-1
    8000111e:	99b2                	add	s3,s3,a2
    80001120:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001124:	893e                	mv	s2,a5
    80001126:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000112a:	6b85                	lui	s7,0x1
    8000112c:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    80001130:	4605                	li	a2,1
    80001132:	85ca                	mv	a1,s2
    80001134:	8556                	mv	a0,s5
    80001136:	00000097          	auipc	ra,0x0
    8000113a:	eda080e7          	jalr	-294(ra) # 80001010 <walk>
    8000113e:	cd1d                	beqz	a0,8000117c <mappages+0x84>
    if(*pte & PTE_V)
    80001140:	611c                	ld	a5,0(a0)
    80001142:	8b85                	andi	a5,a5,1
    80001144:	e785                	bnez	a5,8000116c <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001146:	80b1                	srli	s1,s1,0xc
    80001148:	04aa                	slli	s1,s1,0xa
    8000114a:	0164e4b3          	or	s1,s1,s6
    8000114e:	0014e493          	ori	s1,s1,1
    80001152:	e104                	sd	s1,0(a0)
    if(a == last)
    80001154:	05390063          	beq	s2,s3,80001194 <mappages+0x9c>
    a += PGSIZE;
    80001158:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000115a:	bfc9                	j	8000112c <mappages+0x34>
    panic("mappages: size");
    8000115c:	00007517          	auipc	a0,0x7
    80001160:	f5c50513          	addi	a0,a0,-164 # 800080b8 <etext+0xb8>
    80001164:	fffff097          	auipc	ra,0xfffff
    80001168:	3fc080e7          	jalr	1020(ra) # 80000560 <panic>
      panic("mappages: remap");
    8000116c:	00007517          	auipc	a0,0x7
    80001170:	f5c50513          	addi	a0,a0,-164 # 800080c8 <etext+0xc8>
    80001174:	fffff097          	auipc	ra,0xfffff
    80001178:	3ec080e7          	jalr	1004(ra) # 80000560 <panic>
      return -1;
    8000117c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000117e:	60a6                	ld	ra,72(sp)
    80001180:	6406                	ld	s0,64(sp)
    80001182:	74e2                	ld	s1,56(sp)
    80001184:	7942                	ld	s2,48(sp)
    80001186:	79a2                	ld	s3,40(sp)
    80001188:	7a02                	ld	s4,32(sp)
    8000118a:	6ae2                	ld	s5,24(sp)
    8000118c:	6b42                	ld	s6,16(sp)
    8000118e:	6ba2                	ld	s7,8(sp)
    80001190:	6161                	addi	sp,sp,80
    80001192:	8082                	ret
  return 0;
    80001194:	4501                	li	a0,0
    80001196:	b7e5                	j	8000117e <mappages+0x86>

0000000080001198 <kvmmap>:
{
    80001198:	1141                	addi	sp,sp,-16
    8000119a:	e406                	sd	ra,8(sp)
    8000119c:	e022                	sd	s0,0(sp)
    8000119e:	0800                	addi	s0,sp,16
    800011a0:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011a2:	86b2                	mv	a3,a2
    800011a4:	863e                	mv	a2,a5
    800011a6:	00000097          	auipc	ra,0x0
    800011aa:	f52080e7          	jalr	-174(ra) # 800010f8 <mappages>
    800011ae:	e509                	bnez	a0,800011b8 <kvmmap+0x20>
}
    800011b0:	60a2                	ld	ra,8(sp)
    800011b2:	6402                	ld	s0,0(sp)
    800011b4:	0141                	addi	sp,sp,16
    800011b6:	8082                	ret
    panic("kvmmap");
    800011b8:	00007517          	auipc	a0,0x7
    800011bc:	f2050513          	addi	a0,a0,-224 # 800080d8 <etext+0xd8>
    800011c0:	fffff097          	auipc	ra,0xfffff
    800011c4:	3a0080e7          	jalr	928(ra) # 80000560 <panic>

00000000800011c8 <kvmmake>:
{
    800011c8:	1101                	addi	sp,sp,-32
    800011ca:	ec06                	sd	ra,24(sp)
    800011cc:	e822                	sd	s0,16(sp)
    800011ce:	e426                	sd	s1,8(sp)
    800011d0:	e04a                	sd	s2,0(sp)
    800011d2:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	974080e7          	jalr	-1676(ra) # 80000b48 <kalloc>
    800011dc:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011de:	6605                	lui	a2,0x1
    800011e0:	4581                	li	a1,0
    800011e2:	00000097          	auipc	ra,0x0
    800011e6:	b52080e7          	jalr	-1198(ra) # 80000d34 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ea:	4719                	li	a4,6
    800011ec:	6685                	lui	a3,0x1
    800011ee:	10000637          	lui	a2,0x10000
    800011f2:	100005b7          	lui	a1,0x10000
    800011f6:	8526                	mv	a0,s1
    800011f8:	00000097          	auipc	ra,0x0
    800011fc:	fa0080e7          	jalr	-96(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001200:	4719                	li	a4,6
    80001202:	6685                	lui	a3,0x1
    80001204:	10001637          	lui	a2,0x10001
    80001208:	100015b7          	lui	a1,0x10001
    8000120c:	8526                	mv	a0,s1
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f8a080e7          	jalr	-118(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001216:	4719                	li	a4,6
    80001218:	004006b7          	lui	a3,0x400
    8000121c:	0c000637          	lui	a2,0xc000
    80001220:	0c0005b7          	lui	a1,0xc000
    80001224:	8526                	mv	a0,s1
    80001226:	00000097          	auipc	ra,0x0
    8000122a:	f72080e7          	jalr	-142(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000122e:	00007917          	auipc	s2,0x7
    80001232:	dd290913          	addi	s2,s2,-558 # 80008000 <etext>
    80001236:	4729                	li	a4,10
    80001238:	80007697          	auipc	a3,0x80007
    8000123c:	dc868693          	addi	a3,a3,-568 # 8000 <_entry-0x7fff8000>
    80001240:	4605                	li	a2,1
    80001242:	067e                	slli	a2,a2,0x1f
    80001244:	85b2                	mv	a1,a2
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	f50080e7          	jalr	-176(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001250:	46c5                	li	a3,17
    80001252:	06ee                	slli	a3,a3,0x1b
    80001254:	4719                	li	a4,6
    80001256:	412686b3          	sub	a3,a3,s2
    8000125a:	864a                	mv	a2,s2
    8000125c:	85ca                	mv	a1,s2
    8000125e:	8526                	mv	a0,s1
    80001260:	00000097          	auipc	ra,0x0
    80001264:	f38080e7          	jalr	-200(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001268:	4729                	li	a4,10
    8000126a:	6685                	lui	a3,0x1
    8000126c:	00006617          	auipc	a2,0x6
    80001270:	d9460613          	addi	a2,a2,-620 # 80007000 <_trampoline>
    80001274:	040005b7          	lui	a1,0x4000
    80001278:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000127a:	05b2                	slli	a1,a1,0xc
    8000127c:	8526                	mv	a0,s1
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	f1a080e7          	jalr	-230(ra) # 80001198 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001286:	8526                	mv	a0,s1
    80001288:	00000097          	auipc	ra,0x0
    8000128c:	630080e7          	jalr	1584(ra) # 800018b8 <proc_mapstacks>
}
    80001290:	8526                	mv	a0,s1
    80001292:	60e2                	ld	ra,24(sp)
    80001294:	6442                	ld	s0,16(sp)
    80001296:	64a2                	ld	s1,8(sp)
    80001298:	6902                	ld	s2,0(sp)
    8000129a:	6105                	addi	sp,sp,32
    8000129c:	8082                	ret

000000008000129e <kvminit>:
{
    8000129e:	1141                	addi	sp,sp,-16
    800012a0:	e406                	sd	ra,8(sp)
    800012a2:	e022                	sd	s0,0(sp)
    800012a4:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	f22080e7          	jalr	-222(ra) # 800011c8 <kvmmake>
    800012ae:	0000a797          	auipc	a5,0xa
    800012b2:	0ea7b923          	sd	a0,242(a5) # 8000b3a0 <kernel_pagetable>
}
    800012b6:	60a2                	ld	ra,8(sp)
    800012b8:	6402                	ld	s0,0(sp)
    800012ba:	0141                	addi	sp,sp,16
    800012bc:	8082                	ret

00000000800012be <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012be:	715d                	addi	sp,sp,-80
    800012c0:	e486                	sd	ra,72(sp)
    800012c2:	e0a2                	sd	s0,64(sp)
    800012c4:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012c6:	03459793          	slli	a5,a1,0x34
    800012ca:	e39d                	bnez	a5,800012f0 <uvmunmap+0x32>
    800012cc:	f84a                	sd	s2,48(sp)
    800012ce:	f44e                	sd	s3,40(sp)
    800012d0:	f052                	sd	s4,32(sp)
    800012d2:	ec56                	sd	s5,24(sp)
    800012d4:	e85a                	sd	s6,16(sp)
    800012d6:	e45e                	sd	s7,8(sp)
    800012d8:	8a2a                	mv	s4,a0
    800012da:	892e                	mv	s2,a1
    800012dc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012de:	0632                	slli	a2,a2,0xc
    800012e0:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012e4:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e6:	6b05                	lui	s6,0x1
    800012e8:	0935fb63          	bgeu	a1,s3,8000137e <uvmunmap+0xc0>
    800012ec:	fc26                	sd	s1,56(sp)
    800012ee:	a8a9                	j	80001348 <uvmunmap+0x8a>
    800012f0:	fc26                	sd	s1,56(sp)
    800012f2:	f84a                	sd	s2,48(sp)
    800012f4:	f44e                	sd	s3,40(sp)
    800012f6:	f052                	sd	s4,32(sp)
    800012f8:	ec56                	sd	s5,24(sp)
    800012fa:	e85a                	sd	s6,16(sp)
    800012fc:	e45e                	sd	s7,8(sp)
    panic("uvmunmap: not aligned");
    800012fe:	00007517          	auipc	a0,0x7
    80001302:	de250513          	addi	a0,a0,-542 # 800080e0 <etext+0xe0>
    80001306:	fffff097          	auipc	ra,0xfffff
    8000130a:	25a080e7          	jalr	602(ra) # 80000560 <panic>
      panic("uvmunmap: walk");
    8000130e:	00007517          	auipc	a0,0x7
    80001312:	dea50513          	addi	a0,a0,-534 # 800080f8 <etext+0xf8>
    80001316:	fffff097          	auipc	ra,0xfffff
    8000131a:	24a080e7          	jalr	586(ra) # 80000560 <panic>
      panic("uvmunmap: not mapped");
    8000131e:	00007517          	auipc	a0,0x7
    80001322:	dea50513          	addi	a0,a0,-534 # 80008108 <etext+0x108>
    80001326:	fffff097          	auipc	ra,0xfffff
    8000132a:	23a080e7          	jalr	570(ra) # 80000560 <panic>
      panic("uvmunmap: not a leaf");
    8000132e:	00007517          	auipc	a0,0x7
    80001332:	df250513          	addi	a0,a0,-526 # 80008120 <etext+0x120>
    80001336:	fffff097          	auipc	ra,0xfffff
    8000133a:	22a080e7          	jalr	554(ra) # 80000560 <panic>
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    8000133e:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001342:	995a                	add	s2,s2,s6
    80001344:	03397c63          	bgeu	s2,s3,8000137c <uvmunmap+0xbe>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001348:	4601                	li	a2,0
    8000134a:	85ca                	mv	a1,s2
    8000134c:	8552                	mv	a0,s4
    8000134e:	00000097          	auipc	ra,0x0
    80001352:	cc2080e7          	jalr	-830(ra) # 80001010 <walk>
    80001356:	84aa                	mv	s1,a0
    80001358:	d95d                	beqz	a0,8000130e <uvmunmap+0x50>
    if((*pte & PTE_V) == 0)
    8000135a:	6108                	ld	a0,0(a0)
    8000135c:	00157793          	andi	a5,a0,1
    80001360:	dfdd                	beqz	a5,8000131e <uvmunmap+0x60>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001362:	3ff57793          	andi	a5,a0,1023
    80001366:	fd7784e3          	beq	a5,s7,8000132e <uvmunmap+0x70>
    if(do_free){
    8000136a:	fc0a8ae3          	beqz	s5,8000133e <uvmunmap+0x80>
      uint64 pa = PTE2PA(*pte);
    8000136e:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001370:	0532                	slli	a0,a0,0xc
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	6d8080e7          	jalr	1752(ra) # 80000a4a <kfree>
    8000137a:	b7d1                	j	8000133e <uvmunmap+0x80>
    8000137c:	74e2                	ld	s1,56(sp)
    8000137e:	7942                	ld	s2,48(sp)
    80001380:	79a2                	ld	s3,40(sp)
    80001382:	7a02                	ld	s4,32(sp)
    80001384:	6ae2                	ld	s5,24(sp)
    80001386:	6b42                	ld	s6,16(sp)
    80001388:	6ba2                	ld	s7,8(sp)
  }
}
    8000138a:	60a6                	ld	ra,72(sp)
    8000138c:	6406                	ld	s0,64(sp)
    8000138e:	6161                	addi	sp,sp,80
    80001390:	8082                	ret

0000000080001392 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001392:	1101                	addi	sp,sp,-32
    80001394:	ec06                	sd	ra,24(sp)
    80001396:	e822                	sd	s0,16(sp)
    80001398:	e426                	sd	s1,8(sp)
    8000139a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000139c:	fffff097          	auipc	ra,0xfffff
    800013a0:	7ac080e7          	jalr	1964(ra) # 80000b48 <kalloc>
    800013a4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013a6:	c519                	beqz	a0,800013b4 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	988080e7          	jalr	-1656(ra) # 80000d34 <memset>
  return pagetable;
}
    800013b4:	8526                	mv	a0,s1
    800013b6:	60e2                	ld	ra,24(sp)
    800013b8:	6442                	ld	s0,16(sp)
    800013ba:	64a2                	ld	s1,8(sp)
    800013bc:	6105                	addi	sp,sp,32
    800013be:	8082                	ret

00000000800013c0 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013c0:	7179                	addi	sp,sp,-48
    800013c2:	f406                	sd	ra,40(sp)
    800013c4:	f022                	sd	s0,32(sp)
    800013c6:	ec26                	sd	s1,24(sp)
    800013c8:	e84a                	sd	s2,16(sp)
    800013ca:	e44e                	sd	s3,8(sp)
    800013cc:	e052                	sd	s4,0(sp)
    800013ce:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013d0:	6785                	lui	a5,0x1
    800013d2:	04f67863          	bgeu	a2,a5,80001422 <uvmfirst+0x62>
    800013d6:	8a2a                	mv	s4,a0
    800013d8:	89ae                	mv	s3,a1
    800013da:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	76c080e7          	jalr	1900(ra) # 80000b48 <kalloc>
    800013e4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013e6:	6605                	lui	a2,0x1
    800013e8:	4581                	li	a1,0
    800013ea:	00000097          	auipc	ra,0x0
    800013ee:	94a080e7          	jalr	-1718(ra) # 80000d34 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013f2:	4779                	li	a4,30
    800013f4:	86ca                	mv	a3,s2
    800013f6:	6605                	lui	a2,0x1
    800013f8:	4581                	li	a1,0
    800013fa:	8552                	mv	a0,s4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	cfc080e7          	jalr	-772(ra) # 800010f8 <mappages>
  memmove(mem, src, sz);
    80001404:	8626                	mv	a2,s1
    80001406:	85ce                	mv	a1,s3
    80001408:	854a                	mv	a0,s2
    8000140a:	00000097          	auipc	ra,0x0
    8000140e:	986080e7          	jalr	-1658(ra) # 80000d90 <memmove>
}
    80001412:	70a2                	ld	ra,40(sp)
    80001414:	7402                	ld	s0,32(sp)
    80001416:	64e2                	ld	s1,24(sp)
    80001418:	6942                	ld	s2,16(sp)
    8000141a:	69a2                	ld	s3,8(sp)
    8000141c:	6a02                	ld	s4,0(sp)
    8000141e:	6145                	addi	sp,sp,48
    80001420:	8082                	ret
    panic("uvmfirst: more than a page");
    80001422:	00007517          	auipc	a0,0x7
    80001426:	d1650513          	addi	a0,a0,-746 # 80008138 <etext+0x138>
    8000142a:	fffff097          	auipc	ra,0xfffff
    8000142e:	136080e7          	jalr	310(ra) # 80000560 <panic>

0000000080001432 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001432:	1101                	addi	sp,sp,-32
    80001434:	ec06                	sd	ra,24(sp)
    80001436:	e822                	sd	s0,16(sp)
    80001438:	e426                	sd	s1,8(sp)
    8000143a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000143c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000143e:	00b67d63          	bgeu	a2,a1,80001458 <uvmdealloc+0x26>
    80001442:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001444:	6785                	lui	a5,0x1
    80001446:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001448:	00f60733          	add	a4,a2,a5
    8000144c:	76fd                	lui	a3,0xfffff
    8000144e:	8f75                	and	a4,a4,a3
    80001450:	97ae                	add	a5,a5,a1
    80001452:	8ff5                	and	a5,a5,a3
    80001454:	00f76863          	bltu	a4,a5,80001464 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001458:	8526                	mv	a0,s1
    8000145a:	60e2                	ld	ra,24(sp)
    8000145c:	6442                	ld	s0,16(sp)
    8000145e:	64a2                	ld	s1,8(sp)
    80001460:	6105                	addi	sp,sp,32
    80001462:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001464:	8f99                	sub	a5,a5,a4
    80001466:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001468:	4685                	li	a3,1
    8000146a:	0007861b          	sext.w	a2,a5
    8000146e:	85ba                	mv	a1,a4
    80001470:	00000097          	auipc	ra,0x0
    80001474:	e4e080e7          	jalr	-434(ra) # 800012be <uvmunmap>
    80001478:	b7c5                	j	80001458 <uvmdealloc+0x26>

000000008000147a <uvmalloc>:
  if(newsz < oldsz)
    8000147a:	0ab66b63          	bltu	a2,a1,80001530 <uvmalloc+0xb6>
{
    8000147e:	7139                	addi	sp,sp,-64
    80001480:	fc06                	sd	ra,56(sp)
    80001482:	f822                	sd	s0,48(sp)
    80001484:	ec4e                	sd	s3,24(sp)
    80001486:	e852                	sd	s4,16(sp)
    80001488:	e456                	sd	s5,8(sp)
    8000148a:	0080                	addi	s0,sp,64
    8000148c:	8aaa                	mv	s5,a0
    8000148e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001490:	6785                	lui	a5,0x1
    80001492:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001494:	95be                	add	a1,a1,a5
    80001496:	77fd                	lui	a5,0xfffff
    80001498:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000149c:	08c9fc63          	bgeu	s3,a2,80001534 <uvmalloc+0xba>
    800014a0:	f426                	sd	s1,40(sp)
    800014a2:	f04a                	sd	s2,32(sp)
    800014a4:	e05a                	sd	s6,0(sp)
    800014a6:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014a8:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800014ac:	fffff097          	auipc	ra,0xfffff
    800014b0:	69c080e7          	jalr	1692(ra) # 80000b48 <kalloc>
    800014b4:	84aa                	mv	s1,a0
    if(mem == 0){
    800014b6:	c915                	beqz	a0,800014ea <uvmalloc+0x70>
    memset(mem, 0, PGSIZE);
    800014b8:	6605                	lui	a2,0x1
    800014ba:	4581                	li	a1,0
    800014bc:	00000097          	auipc	ra,0x0
    800014c0:	878080e7          	jalr	-1928(ra) # 80000d34 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014c4:	875a                	mv	a4,s6
    800014c6:	86a6                	mv	a3,s1
    800014c8:	6605                	lui	a2,0x1
    800014ca:	85ca                	mv	a1,s2
    800014cc:	8556                	mv	a0,s5
    800014ce:	00000097          	auipc	ra,0x0
    800014d2:	c2a080e7          	jalr	-982(ra) # 800010f8 <mappages>
    800014d6:	ed05                	bnez	a0,8000150e <uvmalloc+0x94>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014d8:	6785                	lui	a5,0x1
    800014da:	993e                	add	s2,s2,a5
    800014dc:	fd4968e3          	bltu	s2,s4,800014ac <uvmalloc+0x32>
  return newsz;
    800014e0:	8552                	mv	a0,s4
    800014e2:	74a2                	ld	s1,40(sp)
    800014e4:	7902                	ld	s2,32(sp)
    800014e6:	6b02                	ld	s6,0(sp)
    800014e8:	a821                	j	80001500 <uvmalloc+0x86>
      uvmdealloc(pagetable, a, oldsz);
    800014ea:	864e                	mv	a2,s3
    800014ec:	85ca                	mv	a1,s2
    800014ee:	8556                	mv	a0,s5
    800014f0:	00000097          	auipc	ra,0x0
    800014f4:	f42080e7          	jalr	-190(ra) # 80001432 <uvmdealloc>
      return 0;
    800014f8:	4501                	li	a0,0
    800014fa:	74a2                	ld	s1,40(sp)
    800014fc:	7902                	ld	s2,32(sp)
    800014fe:	6b02                	ld	s6,0(sp)
}
    80001500:	70e2                	ld	ra,56(sp)
    80001502:	7442                	ld	s0,48(sp)
    80001504:	69e2                	ld	s3,24(sp)
    80001506:	6a42                	ld	s4,16(sp)
    80001508:	6aa2                	ld	s5,8(sp)
    8000150a:	6121                	addi	sp,sp,64
    8000150c:	8082                	ret
      kfree(mem);
    8000150e:	8526                	mv	a0,s1
    80001510:	fffff097          	auipc	ra,0xfffff
    80001514:	53a080e7          	jalr	1338(ra) # 80000a4a <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001518:	864e                	mv	a2,s3
    8000151a:	85ca                	mv	a1,s2
    8000151c:	8556                	mv	a0,s5
    8000151e:	00000097          	auipc	ra,0x0
    80001522:	f14080e7          	jalr	-236(ra) # 80001432 <uvmdealloc>
      return 0;
    80001526:	4501                	li	a0,0
    80001528:	74a2                	ld	s1,40(sp)
    8000152a:	7902                	ld	s2,32(sp)
    8000152c:	6b02                	ld	s6,0(sp)
    8000152e:	bfc9                	j	80001500 <uvmalloc+0x86>
    return oldsz;
    80001530:	852e                	mv	a0,a1
}
    80001532:	8082                	ret
  return newsz;
    80001534:	8532                	mv	a0,a2
    80001536:	b7e9                	j	80001500 <uvmalloc+0x86>

0000000080001538 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001538:	7179                	addi	sp,sp,-48
    8000153a:	f406                	sd	ra,40(sp)
    8000153c:	f022                	sd	s0,32(sp)
    8000153e:	ec26                	sd	s1,24(sp)
    80001540:	e84a                	sd	s2,16(sp)
    80001542:	e44e                	sd	s3,8(sp)
    80001544:	e052                	sd	s4,0(sp)
    80001546:	1800                	addi	s0,sp,48
    80001548:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000154a:	84aa                	mv	s1,a0
    8000154c:	6905                	lui	s2,0x1
    8000154e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001550:	4985                	li	s3,1
    80001552:	a829                	j	8000156c <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001554:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001556:	00c79513          	slli	a0,a5,0xc
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	fde080e7          	jalr	-34(ra) # 80001538 <freewalk>
      pagetable[i] = 0;
    80001562:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001566:	04a1                	addi	s1,s1,8
    80001568:	03248163          	beq	s1,s2,8000158a <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000156c:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000156e:	00f7f713          	andi	a4,a5,15
    80001572:	ff3701e3          	beq	a4,s3,80001554 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001576:	8b85                	andi	a5,a5,1
    80001578:	d7fd                	beqz	a5,80001566 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000157a:	00007517          	auipc	a0,0x7
    8000157e:	bde50513          	addi	a0,a0,-1058 # 80008158 <etext+0x158>
    80001582:	fffff097          	auipc	ra,0xfffff
    80001586:	fde080e7          	jalr	-34(ra) # 80000560 <panic>
    }
  }
  kfree((void*)pagetable);
    8000158a:	8552                	mv	a0,s4
    8000158c:	fffff097          	auipc	ra,0xfffff
    80001590:	4be080e7          	jalr	1214(ra) # 80000a4a <kfree>
}
    80001594:	70a2                	ld	ra,40(sp)
    80001596:	7402                	ld	s0,32(sp)
    80001598:	64e2                	ld	s1,24(sp)
    8000159a:	6942                	ld	s2,16(sp)
    8000159c:	69a2                	ld	s3,8(sp)
    8000159e:	6a02                	ld	s4,0(sp)
    800015a0:	6145                	addi	sp,sp,48
    800015a2:	8082                	ret

00000000800015a4 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a4:	1101                	addi	sp,sp,-32
    800015a6:	ec06                	sd	ra,24(sp)
    800015a8:	e822                	sd	s0,16(sp)
    800015aa:	e426                	sd	s1,8(sp)
    800015ac:	1000                	addi	s0,sp,32
    800015ae:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b0:	e999                	bnez	a1,800015c6 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b2:	8526                	mv	a0,s1
    800015b4:	00000097          	auipc	ra,0x0
    800015b8:	f84080e7          	jalr	-124(ra) # 80001538 <freewalk>
}
    800015bc:	60e2                	ld	ra,24(sp)
    800015be:	6442                	ld	s0,16(sp)
    800015c0:	64a2                	ld	s1,8(sp)
    800015c2:	6105                	addi	sp,sp,32
    800015c4:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015c6:	6785                	lui	a5,0x1
    800015c8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015ca:	95be                	add	a1,a1,a5
    800015cc:	4685                	li	a3,1
    800015ce:	00c5d613          	srli	a2,a1,0xc
    800015d2:	4581                	li	a1,0
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	cea080e7          	jalr	-790(ra) # 800012be <uvmunmap>
    800015dc:	bfd9                	j	800015b2 <uvmfree+0xe>

00000000800015de <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015de:	c679                	beqz	a2,800016ac <uvmcopy+0xce>
{
    800015e0:	715d                	addi	sp,sp,-80
    800015e2:	e486                	sd	ra,72(sp)
    800015e4:	e0a2                	sd	s0,64(sp)
    800015e6:	fc26                	sd	s1,56(sp)
    800015e8:	f84a                	sd	s2,48(sp)
    800015ea:	f44e                	sd	s3,40(sp)
    800015ec:	f052                	sd	s4,32(sp)
    800015ee:	ec56                	sd	s5,24(sp)
    800015f0:	e85a                	sd	s6,16(sp)
    800015f2:	e45e                	sd	s7,8(sp)
    800015f4:	0880                	addi	s0,sp,80
    800015f6:	8b2a                	mv	s6,a0
    800015f8:	8aae                	mv	s5,a1
    800015fa:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015fc:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015fe:	4601                	li	a2,0
    80001600:	85ce                	mv	a1,s3
    80001602:	855a                	mv	a0,s6
    80001604:	00000097          	auipc	ra,0x0
    80001608:	a0c080e7          	jalr	-1524(ra) # 80001010 <walk>
    8000160c:	c531                	beqz	a0,80001658 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000160e:	6118                	ld	a4,0(a0)
    80001610:	00177793          	andi	a5,a4,1
    80001614:	cbb1                	beqz	a5,80001668 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001616:	00a75593          	srli	a1,a4,0xa
    8000161a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000161e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001622:	fffff097          	auipc	ra,0xfffff
    80001626:	526080e7          	jalr	1318(ra) # 80000b48 <kalloc>
    8000162a:	892a                	mv	s2,a0
    8000162c:	c939                	beqz	a0,80001682 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000162e:	6605                	lui	a2,0x1
    80001630:	85de                	mv	a1,s7
    80001632:	fffff097          	auipc	ra,0xfffff
    80001636:	75e080e7          	jalr	1886(ra) # 80000d90 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000163a:	8726                	mv	a4,s1
    8000163c:	86ca                	mv	a3,s2
    8000163e:	6605                	lui	a2,0x1
    80001640:	85ce                	mv	a1,s3
    80001642:	8556                	mv	a0,s5
    80001644:	00000097          	auipc	ra,0x0
    80001648:	ab4080e7          	jalr	-1356(ra) # 800010f8 <mappages>
    8000164c:	e515                	bnez	a0,80001678 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000164e:	6785                	lui	a5,0x1
    80001650:	99be                	add	s3,s3,a5
    80001652:	fb49e6e3          	bltu	s3,s4,800015fe <uvmcopy+0x20>
    80001656:	a081                	j	80001696 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b1050513          	addi	a0,a0,-1264 # 80008168 <etext+0x168>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	f00080e7          	jalr	-256(ra) # 80000560 <panic>
      panic("uvmcopy: page not present");
    80001668:	00007517          	auipc	a0,0x7
    8000166c:	b2050513          	addi	a0,a0,-1248 # 80008188 <etext+0x188>
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	ef0080e7          	jalr	-272(ra) # 80000560 <panic>
      kfree(mem);
    80001678:	854a                	mv	a0,s2
    8000167a:	fffff097          	auipc	ra,0xfffff
    8000167e:	3d0080e7          	jalr	976(ra) # 80000a4a <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001682:	4685                	li	a3,1
    80001684:	00c9d613          	srli	a2,s3,0xc
    80001688:	4581                	li	a1,0
    8000168a:	8556                	mv	a0,s5
    8000168c:	00000097          	auipc	ra,0x0
    80001690:	c32080e7          	jalr	-974(ra) # 800012be <uvmunmap>
  return -1;
    80001694:	557d                	li	a0,-1
}
    80001696:	60a6                	ld	ra,72(sp)
    80001698:	6406                	ld	s0,64(sp)
    8000169a:	74e2                	ld	s1,56(sp)
    8000169c:	7942                	ld	s2,48(sp)
    8000169e:	79a2                	ld	s3,40(sp)
    800016a0:	7a02                	ld	s4,32(sp)
    800016a2:	6ae2                	ld	s5,24(sp)
    800016a4:	6b42                	ld	s6,16(sp)
    800016a6:	6ba2                	ld	s7,8(sp)
    800016a8:	6161                	addi	sp,sp,80
    800016aa:	8082                	ret
  return 0;
    800016ac:	4501                	li	a0,0
}
    800016ae:	8082                	ret

00000000800016b0 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016b0:	1141                	addi	sp,sp,-16
    800016b2:	e406                	sd	ra,8(sp)
    800016b4:	e022                	sd	s0,0(sp)
    800016b6:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016b8:	4601                	li	a2,0
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	956080e7          	jalr	-1706(ra) # 80001010 <walk>
  if(pte == 0)
    800016c2:	c901                	beqz	a0,800016d2 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016c4:	611c                	ld	a5,0(a0)
    800016c6:	9bbd                	andi	a5,a5,-17
    800016c8:	e11c                	sd	a5,0(a0)
}
    800016ca:	60a2                	ld	ra,8(sp)
    800016cc:	6402                	ld	s0,0(sp)
    800016ce:	0141                	addi	sp,sp,16
    800016d0:	8082                	ret
    panic("uvmclear");
    800016d2:	00007517          	auipc	a0,0x7
    800016d6:	ad650513          	addi	a0,a0,-1322 # 800081a8 <etext+0x1a8>
    800016da:	fffff097          	auipc	ra,0xfffff
    800016de:	e86080e7          	jalr	-378(ra) # 80000560 <panic>

00000000800016e2 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e2:	c6bd                	beqz	a3,80001750 <copyout+0x6e>
{
    800016e4:	715d                	addi	sp,sp,-80
    800016e6:	e486                	sd	ra,72(sp)
    800016e8:	e0a2                	sd	s0,64(sp)
    800016ea:	fc26                	sd	s1,56(sp)
    800016ec:	f84a                	sd	s2,48(sp)
    800016ee:	f44e                	sd	s3,40(sp)
    800016f0:	f052                	sd	s4,32(sp)
    800016f2:	ec56                	sd	s5,24(sp)
    800016f4:	e85a                	sd	s6,16(sp)
    800016f6:	e45e                	sd	s7,8(sp)
    800016f8:	e062                	sd	s8,0(sp)
    800016fa:	0880                	addi	s0,sp,80
    800016fc:	8b2a                	mv	s6,a0
    800016fe:	8c2e                	mv	s8,a1
    80001700:	8a32                	mv	s4,a2
    80001702:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001704:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001706:	6a85                	lui	s5,0x1
    80001708:	a015                	j	8000172c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000170a:	9562                	add	a0,a0,s8
    8000170c:	0004861b          	sext.w	a2,s1
    80001710:	85d2                	mv	a1,s4
    80001712:	41250533          	sub	a0,a0,s2
    80001716:	fffff097          	auipc	ra,0xfffff
    8000171a:	67a080e7          	jalr	1658(ra) # 80000d90 <memmove>

    len -= n;
    8000171e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001722:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001724:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001728:	02098263          	beqz	s3,8000174c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000172c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001730:	85ca                	mv	a1,s2
    80001732:	855a                	mv	a0,s6
    80001734:	00000097          	auipc	ra,0x0
    80001738:	982080e7          	jalr	-1662(ra) # 800010b6 <walkaddr>
    if(pa0 == 0)
    8000173c:	cd01                	beqz	a0,80001754 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000173e:	418904b3          	sub	s1,s2,s8
    80001742:	94d6                	add	s1,s1,s5
    if(n > len)
    80001744:	fc99f3e3          	bgeu	s3,s1,8000170a <copyout+0x28>
    80001748:	84ce                	mv	s1,s3
    8000174a:	b7c1                	j	8000170a <copyout+0x28>
  }
  return 0;
    8000174c:	4501                	li	a0,0
    8000174e:	a021                	j	80001756 <copyout+0x74>
    80001750:	4501                	li	a0,0
}
    80001752:	8082                	ret
      return -1;
    80001754:	557d                	li	a0,-1
}
    80001756:	60a6                	ld	ra,72(sp)
    80001758:	6406                	ld	s0,64(sp)
    8000175a:	74e2                	ld	s1,56(sp)
    8000175c:	7942                	ld	s2,48(sp)
    8000175e:	79a2                	ld	s3,40(sp)
    80001760:	7a02                	ld	s4,32(sp)
    80001762:	6ae2                	ld	s5,24(sp)
    80001764:	6b42                	ld	s6,16(sp)
    80001766:	6ba2                	ld	s7,8(sp)
    80001768:	6c02                	ld	s8,0(sp)
    8000176a:	6161                	addi	sp,sp,80
    8000176c:	8082                	ret

000000008000176e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000176e:	caa5                	beqz	a3,800017de <copyin+0x70>
{
    80001770:	715d                	addi	sp,sp,-80
    80001772:	e486                	sd	ra,72(sp)
    80001774:	e0a2                	sd	s0,64(sp)
    80001776:	fc26                	sd	s1,56(sp)
    80001778:	f84a                	sd	s2,48(sp)
    8000177a:	f44e                	sd	s3,40(sp)
    8000177c:	f052                	sd	s4,32(sp)
    8000177e:	ec56                	sd	s5,24(sp)
    80001780:	e85a                	sd	s6,16(sp)
    80001782:	e45e                	sd	s7,8(sp)
    80001784:	e062                	sd	s8,0(sp)
    80001786:	0880                	addi	s0,sp,80
    80001788:	8b2a                	mv	s6,a0
    8000178a:	8a2e                	mv	s4,a1
    8000178c:	8c32                	mv	s8,a2
    8000178e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001790:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001792:	6a85                	lui	s5,0x1
    80001794:	a01d                	j	800017ba <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001796:	018505b3          	add	a1,a0,s8
    8000179a:	0004861b          	sext.w	a2,s1
    8000179e:	412585b3          	sub	a1,a1,s2
    800017a2:	8552                	mv	a0,s4
    800017a4:	fffff097          	auipc	ra,0xfffff
    800017a8:	5ec080e7          	jalr	1516(ra) # 80000d90 <memmove>

    len -= n;
    800017ac:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017b0:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017b2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017b6:	02098263          	beqz	s3,800017da <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017ba:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017be:	85ca                	mv	a1,s2
    800017c0:	855a                	mv	a0,s6
    800017c2:	00000097          	auipc	ra,0x0
    800017c6:	8f4080e7          	jalr	-1804(ra) # 800010b6 <walkaddr>
    if(pa0 == 0)
    800017ca:	cd01                	beqz	a0,800017e2 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017cc:	418904b3          	sub	s1,s2,s8
    800017d0:	94d6                	add	s1,s1,s5
    if(n > len)
    800017d2:	fc99f2e3          	bgeu	s3,s1,80001796 <copyin+0x28>
    800017d6:	84ce                	mv	s1,s3
    800017d8:	bf7d                	j	80001796 <copyin+0x28>
  }
  return 0;
    800017da:	4501                	li	a0,0
    800017dc:	a021                	j	800017e4 <copyin+0x76>
    800017de:	4501                	li	a0,0
}
    800017e0:	8082                	ret
      return -1;
    800017e2:	557d                	li	a0,-1
}
    800017e4:	60a6                	ld	ra,72(sp)
    800017e6:	6406                	ld	s0,64(sp)
    800017e8:	74e2                	ld	s1,56(sp)
    800017ea:	7942                	ld	s2,48(sp)
    800017ec:	79a2                	ld	s3,40(sp)
    800017ee:	7a02                	ld	s4,32(sp)
    800017f0:	6ae2                	ld	s5,24(sp)
    800017f2:	6b42                	ld	s6,16(sp)
    800017f4:	6ba2                	ld	s7,8(sp)
    800017f6:	6c02                	ld	s8,0(sp)
    800017f8:	6161                	addi	sp,sp,80
    800017fa:	8082                	ret

00000000800017fc <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017fc:	cacd                	beqz	a3,800018ae <copyinstr+0xb2>
{
    800017fe:	715d                	addi	sp,sp,-80
    80001800:	e486                	sd	ra,72(sp)
    80001802:	e0a2                	sd	s0,64(sp)
    80001804:	fc26                	sd	s1,56(sp)
    80001806:	f84a                	sd	s2,48(sp)
    80001808:	f44e                	sd	s3,40(sp)
    8000180a:	f052                	sd	s4,32(sp)
    8000180c:	ec56                	sd	s5,24(sp)
    8000180e:	e85a                	sd	s6,16(sp)
    80001810:	e45e                	sd	s7,8(sp)
    80001812:	0880                	addi	s0,sp,80
    80001814:	8a2a                	mv	s4,a0
    80001816:	8b2e                	mv	s6,a1
    80001818:	8bb2                	mv	s7,a2
    8000181a:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(srcva);
    8000181c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000181e:	6985                	lui	s3,0x1
    80001820:	a825                	j	80001858 <copyinstr+0x5c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001822:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001826:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001828:	37fd                	addiw	a5,a5,-1
    8000182a:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000182e:	60a6                	ld	ra,72(sp)
    80001830:	6406                	ld	s0,64(sp)
    80001832:	74e2                	ld	s1,56(sp)
    80001834:	7942                	ld	s2,48(sp)
    80001836:	79a2                	ld	s3,40(sp)
    80001838:	7a02                	ld	s4,32(sp)
    8000183a:	6ae2                	ld	s5,24(sp)
    8000183c:	6b42                	ld	s6,16(sp)
    8000183e:	6ba2                	ld	s7,8(sp)
    80001840:	6161                	addi	sp,sp,80
    80001842:	8082                	ret
    80001844:	fff90713          	addi	a4,s2,-1 # fff <_entry-0x7ffff001>
    80001848:	9742                	add	a4,a4,a6
      --max;
    8000184a:	40b70933          	sub	s2,a4,a1
    srcva = va0 + PGSIZE;
    8000184e:	01348bb3          	add	s7,s1,s3
  while(got_null == 0 && max > 0){
    80001852:	04e58663          	beq	a1,a4,8000189e <copyinstr+0xa2>
{
    80001856:	8b3e                	mv	s6,a5
    va0 = PGROUNDDOWN(srcva);
    80001858:	015bf4b3          	and	s1,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000185c:	85a6                	mv	a1,s1
    8000185e:	8552                	mv	a0,s4
    80001860:	00000097          	auipc	ra,0x0
    80001864:	856080e7          	jalr	-1962(ra) # 800010b6 <walkaddr>
    if(pa0 == 0)
    80001868:	cd0d                	beqz	a0,800018a2 <copyinstr+0xa6>
    n = PGSIZE - (srcva - va0);
    8000186a:	417486b3          	sub	a3,s1,s7
    8000186e:	96ce                	add	a3,a3,s3
    if(n > max)
    80001870:	00d97363          	bgeu	s2,a3,80001876 <copyinstr+0x7a>
    80001874:	86ca                	mv	a3,s2
    char *p = (char *) (pa0 + (srcva - va0));
    80001876:	955e                	add	a0,a0,s7
    80001878:	8d05                	sub	a0,a0,s1
    while(n > 0){
    8000187a:	c695                	beqz	a3,800018a6 <copyinstr+0xaa>
    8000187c:	87da                	mv	a5,s6
    8000187e:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001880:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001884:	96da                	add	a3,a3,s6
    80001886:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001888:	00f60733          	add	a4,a2,a5
    8000188c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd79d0>
    80001890:	db49                	beqz	a4,80001822 <copyinstr+0x26>
        *dst = *p;
    80001892:	00e78023          	sb	a4,0(a5)
      dst++;
    80001896:	0785                	addi	a5,a5,1
    while(n > 0){
    80001898:	fed797e3          	bne	a5,a3,80001886 <copyinstr+0x8a>
    8000189c:	b765                	j	80001844 <copyinstr+0x48>
    8000189e:	4781                	li	a5,0
    800018a0:	b761                	j	80001828 <copyinstr+0x2c>
      return -1;
    800018a2:	557d                	li	a0,-1
    800018a4:	b769                	j	8000182e <copyinstr+0x32>
    srcva = va0 + PGSIZE;
    800018a6:	6b85                	lui	s7,0x1
    800018a8:	9ba6                	add	s7,s7,s1
    800018aa:	87da                	mv	a5,s6
    800018ac:	b76d                	j	80001856 <copyinstr+0x5a>
  int got_null = 0;
    800018ae:	4781                	li	a5,0
  if(got_null){
    800018b0:	37fd                	addiw	a5,a5,-1
    800018b2:	0007851b          	sext.w	a0,a5
}
    800018b6:	8082                	ret

00000000800018b8 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    800018b8:	7139                	addi	sp,sp,-64
    800018ba:	fc06                	sd	ra,56(sp)
    800018bc:	f822                	sd	s0,48(sp)
    800018be:	f426                	sd	s1,40(sp)
    800018c0:	f04a                	sd	s2,32(sp)
    800018c2:	ec4e                	sd	s3,24(sp)
    800018c4:	e852                	sd	s4,16(sp)
    800018c6:	e456                	sd	s5,8(sp)
    800018c8:	e05a                	sd	s6,0(sp)
    800018ca:	0080                	addi	s0,sp,64
    800018cc:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800018ce:	00012497          	auipc	s1,0x12
    800018d2:	18248493          	addi	s1,s1,386 # 80013a50 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    800018d6:	8b26                	mv	s6,s1
    800018d8:	ff0f1937          	lui	s2,0xff0f1
    800018dc:	f0f90913          	addi	s2,s2,-241 # ffffffffff0f0f0f <end+0xffffffff7f0c98df>
    800018e0:	0932                	slli	s2,s2,0xc
    800018e2:	0f190913          	addi	s2,s2,241
    800018e6:	0932                	slli	s2,s2,0xc
    800018e8:	f0f90913          	addi	s2,s2,-241
    800018ec:	0932                	slli	s2,s2,0xc
    800018ee:	0f190913          	addi	s2,s2,241
    800018f2:	040009b7          	lui	s3,0x4000
    800018f6:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    800018f8:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    800018fa:	0001ba97          	auipc	s5,0x1b
    800018fe:	956a8a93          	addi	s5,s5,-1706 # 8001c250 <tickslock>
    char *pa = kalloc();
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	246080e7          	jalr	582(ra) # 80000b48 <kalloc>
    8000190a:	862a                	mv	a2,a0
    if (pa == 0)
    8000190c:	c121                	beqz	a0,8000194c <proc_mapstacks+0x94>
    uint64 va = KSTACK((int)(p - proc));
    8000190e:	416485b3          	sub	a1,s1,s6
    80001912:	8595                	srai	a1,a1,0x5
    80001914:	032585b3          	mul	a1,a1,s2
    80001918:	2585                	addiw	a1,a1,1
    8000191a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000191e:	4719                	li	a4,6
    80001920:	6685                	lui	a3,0x1
    80001922:	40b985b3          	sub	a1,s3,a1
    80001926:	8552                	mv	a0,s4
    80001928:	00000097          	auipc	ra,0x0
    8000192c:	870080e7          	jalr	-1936(ra) # 80001198 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001930:	22048493          	addi	s1,s1,544
    80001934:	fd5497e3          	bne	s1,s5,80001902 <proc_mapstacks+0x4a>
  }
}
    80001938:	70e2                	ld	ra,56(sp)
    8000193a:	7442                	ld	s0,48(sp)
    8000193c:	74a2                	ld	s1,40(sp)
    8000193e:	7902                	ld	s2,32(sp)
    80001940:	69e2                	ld	s3,24(sp)
    80001942:	6a42                	ld	s4,16(sp)
    80001944:	6aa2                	ld	s5,8(sp)
    80001946:	6b02                	ld	s6,0(sp)
    80001948:	6121                	addi	sp,sp,64
    8000194a:	8082                	ret
      panic("kalloc");
    8000194c:	00007517          	auipc	a0,0x7
    80001950:	86c50513          	addi	a0,a0,-1940 # 800081b8 <etext+0x1b8>
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	c0c080e7          	jalr	-1012(ra) # 80000560 <panic>

000000008000195c <procinit>:

// initialize the proc table.
void procinit(void)
{
    8000195c:	7139                	addi	sp,sp,-64
    8000195e:	fc06                	sd	ra,56(sp)
    80001960:	f822                	sd	s0,48(sp)
    80001962:	f426                	sd	s1,40(sp)
    80001964:	f04a                	sd	s2,32(sp)
    80001966:	ec4e                	sd	s3,24(sp)
    80001968:	e852                	sd	s4,16(sp)
    8000196a:	e456                	sd	s5,8(sp)
    8000196c:	e05a                	sd	s6,0(sp)
    8000196e:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001970:	00007597          	auipc	a1,0x7
    80001974:	85058593          	addi	a1,a1,-1968 # 800081c0 <etext+0x1c0>
    80001978:	00012517          	auipc	a0,0x12
    8000197c:	ca850513          	addi	a0,a0,-856 # 80013620 <pid_lock>
    80001980:	fffff097          	auipc	ra,0xfffff
    80001984:	228080e7          	jalr	552(ra) # 80000ba8 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001988:	00007597          	auipc	a1,0x7
    8000198c:	84058593          	addi	a1,a1,-1984 # 800081c8 <etext+0x1c8>
    80001990:	00012517          	auipc	a0,0x12
    80001994:	ca850513          	addi	a0,a0,-856 # 80013638 <wait_lock>
    80001998:	fffff097          	auipc	ra,0xfffff
    8000199c:	210080e7          	jalr	528(ra) # 80000ba8 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    800019a0:	00012497          	auipc	s1,0x12
    800019a4:	0b048493          	addi	s1,s1,176 # 80013a50 <proc>
  {
    initlock(&p->lock, "proc");
    800019a8:	00007b17          	auipc	s6,0x7
    800019ac:	830b0b13          	addi	s6,s6,-2000 # 800081d8 <etext+0x1d8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    800019b0:	8aa6                	mv	s5,s1
    800019b2:	ff0f1937          	lui	s2,0xff0f1
    800019b6:	f0f90913          	addi	s2,s2,-241 # ffffffffff0f0f0f <end+0xffffffff7f0c98df>
    800019ba:	0932                	slli	s2,s2,0xc
    800019bc:	0f190913          	addi	s2,s2,241
    800019c0:	0932                	slli	s2,s2,0xc
    800019c2:	f0f90913          	addi	s2,s2,-241
    800019c6:	0932                	slli	s2,s2,0xc
    800019c8:	0f190913          	addi	s2,s2,241
    800019cc:	040009b7          	lui	s3,0x4000
    800019d0:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    800019d2:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    800019d4:	0001ba17          	auipc	s4,0x1b
    800019d8:	87ca0a13          	addi	s4,s4,-1924 # 8001c250 <tickslock>
    initlock(&p->lock, "proc");
    800019dc:	85da                	mv	a1,s6
    800019de:	8526                	mv	a0,s1
    800019e0:	fffff097          	auipc	ra,0xfffff
    800019e4:	1c8080e7          	jalr	456(ra) # 80000ba8 <initlock>
    p->state = UNUSED;
    800019e8:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    800019ec:	415487b3          	sub	a5,s1,s5
    800019f0:	8795                	srai	a5,a5,0x5
    800019f2:	032787b3          	mul	a5,a5,s2
    800019f6:	2785                	addiw	a5,a5,1
    800019f8:	00d7979b          	slliw	a5,a5,0xd
    800019fc:	40f987b3          	sub	a5,s3,a5
    80001a00:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a02:	22048493          	addi	s1,s1,544
    80001a06:	fd449be3          	bne	s1,s4,800019dc <procinit+0x80>
  }
}
    80001a0a:	70e2                	ld	ra,56(sp)
    80001a0c:	7442                	ld	s0,48(sp)
    80001a0e:	74a2                	ld	s1,40(sp)
    80001a10:	7902                	ld	s2,32(sp)
    80001a12:	69e2                	ld	s3,24(sp)
    80001a14:	6a42                	ld	s4,16(sp)
    80001a16:	6aa2                	ld	s5,8(sp)
    80001a18:	6b02                	ld	s6,0(sp)
    80001a1a:	6121                	addi	sp,sp,64
    80001a1c:	8082                	ret

0000000080001a1e <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001a1e:	1141                	addi	sp,sp,-16
    80001a20:	e422                	sd	s0,8(sp)
    80001a22:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a24:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a26:	2501                	sext.w	a0,a0
    80001a28:	6422                	ld	s0,8(sp)
    80001a2a:	0141                	addi	sp,sp,16
    80001a2c:	8082                	ret

0000000080001a2e <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001a2e:	1141                	addi	sp,sp,-16
    80001a30:	e422                	sd	s0,8(sp)
    80001a32:	0800                	addi	s0,sp,16
    80001a34:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a36:	2781                	sext.w	a5,a5
    80001a38:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a3a:	00012517          	auipc	a0,0x12
    80001a3e:	c1650513          	addi	a0,a0,-1002 # 80013650 <cpus>
    80001a42:	953e                	add	a0,a0,a5
    80001a44:	6422                	ld	s0,8(sp)
    80001a46:	0141                	addi	sp,sp,16
    80001a48:	8082                	ret

0000000080001a4a <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001a4a:	1101                	addi	sp,sp,-32
    80001a4c:	ec06                	sd	ra,24(sp)
    80001a4e:	e822                	sd	s0,16(sp)
    80001a50:	e426                	sd	s1,8(sp)
    80001a52:	1000                	addi	s0,sp,32
  push_off();
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	198080e7          	jalr	408(ra) # 80000bec <push_off>
    80001a5c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a5e:	2781                	sext.w	a5,a5
    80001a60:	079e                	slli	a5,a5,0x7
    80001a62:	00012717          	auipc	a4,0x12
    80001a66:	bbe70713          	addi	a4,a4,-1090 # 80013620 <pid_lock>
    80001a6a:	97ba                	add	a5,a5,a4
    80001a6c:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	21e080e7          	jalr	542(ra) # 80000c8c <pop_off>
  return p;
}
    80001a76:	8526                	mv	a0,s1
    80001a78:	60e2                	ld	ra,24(sp)
    80001a7a:	6442                	ld	s0,16(sp)
    80001a7c:	64a2                	ld	s1,8(sp)
    80001a7e:	6105                	addi	sp,sp,32
    80001a80:	8082                	ret

0000000080001a82 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001a82:	1141                	addi	sp,sp,-16
    80001a84:	e406                	sd	ra,8(sp)
    80001a86:	e022                	sd	s0,0(sp)
    80001a88:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a8a:	00000097          	auipc	ra,0x0
    80001a8e:	fc0080e7          	jalr	-64(ra) # 80001a4a <myproc>
    80001a92:	fffff097          	auipc	ra,0xfffff
    80001a96:	25a080e7          	jalr	602(ra) # 80000cec <release>

  if (first)
    80001a9a:	0000a797          	auipc	a5,0xa
    80001a9e:	8767a783          	lw	a5,-1930(a5) # 8000b310 <first.1>
    80001aa2:	eb89                	bnez	a5,80001ab4 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001aa4:	00001097          	auipc	ra,0x1
    80001aa8:	064080e7          	jalr	100(ra) # 80002b08 <usertrapret>
}
    80001aac:	60a2                	ld	ra,8(sp)
    80001aae:	6402                	ld	s0,0(sp)
    80001ab0:	0141                	addi	sp,sp,16
    80001ab2:	8082                	ret
    first = 0;
    80001ab4:	0000a797          	auipc	a5,0xa
    80001ab8:	8407ae23          	sw	zero,-1956(a5) # 8000b310 <first.1>
    fsinit(ROOTDEV);
    80001abc:	4505                	li	a0,1
    80001abe:	00002097          	auipc	ra,0x2
    80001ac2:	fca080e7          	jalr	-54(ra) # 80003a88 <fsinit>
    80001ac6:	bff9                	j	80001aa4 <forkret+0x22>

0000000080001ac8 <allocpid>:
{
    80001ac8:	1101                	addi	sp,sp,-32
    80001aca:	ec06                	sd	ra,24(sp)
    80001acc:	e822                	sd	s0,16(sp)
    80001ace:	e426                	sd	s1,8(sp)
    80001ad0:	e04a                	sd	s2,0(sp)
    80001ad2:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ad4:	00012917          	auipc	s2,0x12
    80001ad8:	b4c90913          	addi	s2,s2,-1204 # 80013620 <pid_lock>
    80001adc:	854a                	mv	a0,s2
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	15a080e7          	jalr	346(ra) # 80000c38 <acquire>
  pid = nextpid;
    80001ae6:	0000a797          	auipc	a5,0xa
    80001aea:	83278793          	addi	a5,a5,-1998 # 8000b318 <nextpid>
    80001aee:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001af0:	0014871b          	addiw	a4,s1,1
    80001af4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001af6:	854a                	mv	a0,s2
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	1f4080e7          	jalr	500(ra) # 80000cec <release>
}
    80001b00:	8526                	mv	a0,s1
    80001b02:	60e2                	ld	ra,24(sp)
    80001b04:	6442                	ld	s0,16(sp)
    80001b06:	64a2                	ld	s1,8(sp)
    80001b08:	6902                	ld	s2,0(sp)
    80001b0a:	6105                	addi	sp,sp,32
    80001b0c:	8082                	ret

0000000080001b0e <proc_pagetable>:
{
    80001b0e:	1101                	addi	sp,sp,-32
    80001b10:	ec06                	sd	ra,24(sp)
    80001b12:	e822                	sd	s0,16(sp)
    80001b14:	e426                	sd	s1,8(sp)
    80001b16:	e04a                	sd	s2,0(sp)
    80001b18:	1000                	addi	s0,sp,32
    80001b1a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	876080e7          	jalr	-1930(ra) # 80001392 <uvmcreate>
    80001b24:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001b26:	c121                	beqz	a0,80001b66 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b28:	4729                	li	a4,10
    80001b2a:	00005697          	auipc	a3,0x5
    80001b2e:	4d668693          	addi	a3,a3,1238 # 80007000 <_trampoline>
    80001b32:	6605                	lui	a2,0x1
    80001b34:	040005b7          	lui	a1,0x4000
    80001b38:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b3a:	05b2                	slli	a1,a1,0xc
    80001b3c:	fffff097          	auipc	ra,0xfffff
    80001b40:	5bc080e7          	jalr	1468(ra) # 800010f8 <mappages>
    80001b44:	02054863          	bltz	a0,80001b74 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b48:	4719                	li	a4,6
    80001b4a:	05893683          	ld	a3,88(s2)
    80001b4e:	6605                	lui	a2,0x1
    80001b50:	020005b7          	lui	a1,0x2000
    80001b54:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b56:	05b6                	slli	a1,a1,0xd
    80001b58:	8526                	mv	a0,s1
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	59e080e7          	jalr	1438(ra) # 800010f8 <mappages>
    80001b62:	02054163          	bltz	a0,80001b84 <proc_pagetable+0x76>
}
    80001b66:	8526                	mv	a0,s1
    80001b68:	60e2                	ld	ra,24(sp)
    80001b6a:	6442                	ld	s0,16(sp)
    80001b6c:	64a2                	ld	s1,8(sp)
    80001b6e:	6902                	ld	s2,0(sp)
    80001b70:	6105                	addi	sp,sp,32
    80001b72:	8082                	ret
    uvmfree(pagetable, 0);
    80001b74:	4581                	li	a1,0
    80001b76:	8526                	mv	a0,s1
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	a2c080e7          	jalr	-1492(ra) # 800015a4 <uvmfree>
    return 0;
    80001b80:	4481                	li	s1,0
    80001b82:	b7d5                	j	80001b66 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b84:	4681                	li	a3,0
    80001b86:	4605                	li	a2,1
    80001b88:	040005b7          	lui	a1,0x4000
    80001b8c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b8e:	05b2                	slli	a1,a1,0xc
    80001b90:	8526                	mv	a0,s1
    80001b92:	fffff097          	auipc	ra,0xfffff
    80001b96:	72c080e7          	jalr	1836(ra) # 800012be <uvmunmap>
    uvmfree(pagetable, 0);
    80001b9a:	4581                	li	a1,0
    80001b9c:	8526                	mv	a0,s1
    80001b9e:	00000097          	auipc	ra,0x0
    80001ba2:	a06080e7          	jalr	-1530(ra) # 800015a4 <uvmfree>
    return 0;
    80001ba6:	4481                	li	s1,0
    80001ba8:	bf7d                	j	80001b66 <proc_pagetable+0x58>

0000000080001baa <proc_freepagetable>:
{
    80001baa:	1101                	addi	sp,sp,-32
    80001bac:	ec06                	sd	ra,24(sp)
    80001bae:	e822                	sd	s0,16(sp)
    80001bb0:	e426                	sd	s1,8(sp)
    80001bb2:	e04a                	sd	s2,0(sp)
    80001bb4:	1000                	addi	s0,sp,32
    80001bb6:	84aa                	mv	s1,a0
    80001bb8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bba:	4681                	li	a3,0
    80001bbc:	4605                	li	a2,1
    80001bbe:	040005b7          	lui	a1,0x4000
    80001bc2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bc4:	05b2                	slli	a1,a1,0xc
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	6f8080e7          	jalr	1784(ra) # 800012be <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bce:	4681                	li	a3,0
    80001bd0:	4605                	li	a2,1
    80001bd2:	020005b7          	lui	a1,0x2000
    80001bd6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bd8:	05b6                	slli	a1,a1,0xd
    80001bda:	8526                	mv	a0,s1
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	6e2080e7          	jalr	1762(ra) # 800012be <uvmunmap>
  uvmfree(pagetable, sz);
    80001be4:	85ca                	mv	a1,s2
    80001be6:	8526                	mv	a0,s1
    80001be8:	00000097          	auipc	ra,0x0
    80001bec:	9bc080e7          	jalr	-1604(ra) # 800015a4 <uvmfree>
}
    80001bf0:	60e2                	ld	ra,24(sp)
    80001bf2:	6442                	ld	s0,16(sp)
    80001bf4:	64a2                	ld	s1,8(sp)
    80001bf6:	6902                	ld	s2,0(sp)
    80001bf8:	6105                	addi	sp,sp,32
    80001bfa:	8082                	ret

0000000080001bfc <freeproc>:
{
    80001bfc:	1101                	addi	sp,sp,-32
    80001bfe:	ec06                	sd	ra,24(sp)
    80001c00:	e822                	sd	s0,16(sp)
    80001c02:	e426                	sd	s1,8(sp)
    80001c04:	1000                	addi	s0,sp,32
    80001c06:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001c08:	6d28                	ld	a0,88(a0)
    80001c0a:	c509                	beqz	a0,80001c14 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	e3e080e7          	jalr	-450(ra) # 80000a4a <kfree>
  p->trapframe = 0;
    80001c14:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001c18:	68a8                	ld	a0,80(s1)
    80001c1a:	c511                	beqz	a0,80001c26 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c1c:	64ac                	ld	a1,72(s1)
    80001c1e:	00000097          	auipc	ra,0x0
    80001c22:	f8c080e7          	jalr	-116(ra) # 80001baa <proc_freepagetable>
  p->pagetable = 0;
    80001c26:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c2a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c2e:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c32:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c36:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c3a:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c3e:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c42:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c46:	0004ac23          	sw	zero,24(s1)
}
    80001c4a:	60e2                	ld	ra,24(sp)
    80001c4c:	6442                	ld	s0,16(sp)
    80001c4e:	64a2                	ld	s1,8(sp)
    80001c50:	6105                	addi	sp,sp,32
    80001c52:	8082                	ret

0000000080001c54 <allocproc>:
{
    80001c54:	1101                	addi	sp,sp,-32
    80001c56:	ec06                	sd	ra,24(sp)
    80001c58:	e822                	sd	s0,16(sp)
    80001c5a:	e426                	sd	s1,8(sp)
    80001c5c:	e04a                	sd	s2,0(sp)
    80001c5e:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001c60:	00012497          	auipc	s1,0x12
    80001c64:	df048493          	addi	s1,s1,-528 # 80013a50 <proc>
    80001c68:	0001a917          	auipc	s2,0x1a
    80001c6c:	5e890913          	addi	s2,s2,1512 # 8001c250 <tickslock>
    acquire(&p->lock);
    80001c70:	8526                	mv	a0,s1
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	fc6080e7          	jalr	-58(ra) # 80000c38 <acquire>
    if (p->state == UNUSED)
    80001c7a:	4c9c                	lw	a5,24(s1)
    80001c7c:	cf81                	beqz	a5,80001c94 <allocproc+0x40>
      release(&p->lock);
    80001c7e:	8526                	mv	a0,s1
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	06c080e7          	jalr	108(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c88:	22048493          	addi	s1,s1,544
    80001c8c:	ff2492e3          	bne	s1,s2,80001c70 <allocproc+0x1c>
  return 0;
    80001c90:	4481                	li	s1,0
    80001c92:	a855                	j	80001d46 <allocproc+0xf2>
  p->pid = allocpid();
    80001c94:	00000097          	auipc	ra,0x0
    80001c98:	e34080e7          	jalr	-460(ra) # 80001ac8 <allocpid>
    80001c9c:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c9e:	4785                	li	a5,1
    80001ca0:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	ea6080e7          	jalr	-346(ra) # 80000b48 <kalloc>
    80001caa:	892a                	mv	s2,a0
    80001cac:	eca8                	sd	a0,88(s1)
    80001cae:	c15d                	beqz	a0,80001d54 <allocproc+0x100>
  p->pagetable = proc_pagetable(p);
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	e5c080e7          	jalr	-420(ra) # 80001b0e <proc_pagetable>
    80001cba:	892a                	mv	s2,a0
    80001cbc:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001cbe:	c55d                	beqz	a0,80001d6c <allocproc+0x118>
  memset(&p->context, 0, sizeof(p->context));
    80001cc0:	07000613          	li	a2,112
    80001cc4:	4581                	li	a1,0
    80001cc6:	06048513          	addi	a0,s1,96
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	06a080e7          	jalr	106(ra) # 80000d34 <memset>
  p->context.ra = (uint64)forkret;
    80001cd2:	00000797          	auipc	a5,0x0
    80001cd6:	db078793          	addi	a5,a5,-592 # 80001a82 <forkret>
    80001cda:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cdc:	60bc                	ld	a5,64(s1)
    80001cde:	6705                	lui	a4,0x1
    80001ce0:	97ba                	add	a5,a5,a4
    80001ce2:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001ce4:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001ce8:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001cec:	00009797          	auipc	a5,0x9
    80001cf0:	6c47a783          	lw	a5,1732(a5) # 8000b3b0 <ticks>
    80001cf4:	16f4a623          	sw	a5,364(s1)
  for(int i=0; i<31; i++){
    80001cf8:	17448793          	addi	a5,s1,372
    80001cfc:	1f048713          	addi	a4,s1,496
    p->syscall_count[i] = 0;
    80001d00:	0007a023          	sw	zero,0(a5)
  for(int i=0; i<31; i++){
    80001d04:	0791                	addi	a5,a5,4
    80001d06:	fee79de3          	bne	a5,a4,80001d00 <allocproc+0xac>
  p->alarmticks = 0;
    80001d0a:	1e04a823          	sw	zero,496(s1)
  p->ticks_left = 0;
    80001d0e:	1e04aa23          	sw	zero,500(s1)
  p->alarm_handler = 0;
    80001d12:	1e04bc23          	sd	zero,504(s1)
  p->in_alarm = 0;
    80001d16:	2004a423          	sw	zero,520(s1)
  p->original_trapframe = kalloc();  // Allocate space for the trapframe
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	e2e080e7          	jalr	-466(ra) # 80000b48 <kalloc>
    80001d22:	20a4b023          	sd	a0,512(s1)
  if (p->original_trapframe == 0)
    80001d26:	cd39                	beqz	a0,80001d84 <allocproc+0x130>
  p->tickets = 1;  // Default number of tickets is 1
    80001d28:	4785                	li	a5,1
    80001d2a:	20f4a623          	sw	a5,524(s1)
  p->arrival_time = ticks;  // Store the current tick count
    80001d2e:	00009717          	auipc	a4,0x9
    80001d32:	68272703          	lw	a4,1666(a4) # 8000b3b0 <ticks>
    80001d36:	20e4a823          	sw	a4,528(s1)
  p->priority = 0;       // Start at highest priority
    80001d3a:	2004aa23          	sw	zero,532(s1)
  p->time_slices = 1;    // Time slice for priority 0
    80001d3e:	20f4ac23          	sw	a5,536(s1)
  p->ticks_in_level = 0; // No ticks used yet
    80001d42:	2004ae23          	sw	zero,540(s1)
}
    80001d46:	8526                	mv	a0,s1
    80001d48:	60e2                	ld	ra,24(sp)
    80001d4a:	6442                	ld	s0,16(sp)
    80001d4c:	64a2                	ld	s1,8(sp)
    80001d4e:	6902                	ld	s2,0(sp)
    80001d50:	6105                	addi	sp,sp,32
    80001d52:	8082                	ret
    freeproc(p);
    80001d54:	8526                	mv	a0,s1
    80001d56:	00000097          	auipc	ra,0x0
    80001d5a:	ea6080e7          	jalr	-346(ra) # 80001bfc <freeproc>
    release(&p->lock);
    80001d5e:	8526                	mv	a0,s1
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	f8c080e7          	jalr	-116(ra) # 80000cec <release>
    return 0;
    80001d68:	84ca                	mv	s1,s2
    80001d6a:	bff1                	j	80001d46 <allocproc+0xf2>
    freeproc(p);
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	00000097          	auipc	ra,0x0
    80001d72:	e8e080e7          	jalr	-370(ra) # 80001bfc <freeproc>
    release(&p->lock);
    80001d76:	8526                	mv	a0,s1
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	f74080e7          	jalr	-140(ra) # 80000cec <release>
    return 0;
    80001d80:	84ca                	mv	s1,s2
    80001d82:	b7d1                	j	80001d46 <allocproc+0xf2>
    return 0;
    80001d84:	84aa                	mv	s1,a0
    80001d86:	b7c1                	j	80001d46 <allocproc+0xf2>

0000000080001d88 <userinit>:
{
    80001d88:	1101                	addi	sp,sp,-32
    80001d8a:	ec06                	sd	ra,24(sp)
    80001d8c:	e822                	sd	s0,16(sp)
    80001d8e:	e426                	sd	s1,8(sp)
    80001d90:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	ec2080e7          	jalr	-318(ra) # 80001c54 <allocproc>
    80001d9a:	84aa                	mv	s1,a0
  initproc = p;
    80001d9c:	00009797          	auipc	a5,0x9
    80001da0:	60a7b623          	sd	a0,1548(a5) # 8000b3a8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001da4:	03400613          	li	a2,52
    80001da8:	00009597          	auipc	a1,0x9
    80001dac:	57858593          	addi	a1,a1,1400 # 8000b320 <initcode>
    80001db0:	6928                	ld	a0,80(a0)
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	60e080e7          	jalr	1550(ra) # 800013c0 <uvmfirst>
  p->sz = PGSIZE;
    80001dba:	6785                	lui	a5,0x1
    80001dbc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001dbe:	6cb8                	ld	a4,88(s1)
    80001dc0:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001dc4:	6cb8                	ld	a4,88(s1)
    80001dc6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dc8:	4641                	li	a2,16
    80001dca:	00006597          	auipc	a1,0x6
    80001dce:	41658593          	addi	a1,a1,1046 # 800081e0 <etext+0x1e0>
    80001dd2:	15848513          	addi	a0,s1,344
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	0a0080e7          	jalr	160(ra) # 80000e76 <safestrcpy>
  p->cwd = namei("/");
    80001dde:	00006517          	auipc	a0,0x6
    80001de2:	41250513          	addi	a0,a0,1042 # 800081f0 <etext+0x1f0>
    80001de6:	00002097          	auipc	ra,0x2
    80001dea:	6f4080e7          	jalr	1780(ra) # 800044da <namei>
    80001dee:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001df2:	478d                	li	a5,3
    80001df4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001df6:	8526                	mv	a0,s1
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	ef4080e7          	jalr	-268(ra) # 80000cec <release>
}
    80001e00:	60e2                	ld	ra,24(sp)
    80001e02:	6442                	ld	s0,16(sp)
    80001e04:	64a2                	ld	s1,8(sp)
    80001e06:	6105                	addi	sp,sp,32
    80001e08:	8082                	ret

0000000080001e0a <growproc>:
{
    80001e0a:	1101                	addi	sp,sp,-32
    80001e0c:	ec06                	sd	ra,24(sp)
    80001e0e:	e822                	sd	s0,16(sp)
    80001e10:	e426                	sd	s1,8(sp)
    80001e12:	e04a                	sd	s2,0(sp)
    80001e14:	1000                	addi	s0,sp,32
    80001e16:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	c32080e7          	jalr	-974(ra) # 80001a4a <myproc>
    80001e20:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e22:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001e24:	01204c63          	bgtz	s2,80001e3c <growproc+0x32>
  else if (n < 0)
    80001e28:	02094663          	bltz	s2,80001e54 <growproc+0x4a>
  p->sz = sz;
    80001e2c:	e4ac                	sd	a1,72(s1)
  return 0;
    80001e2e:	4501                	li	a0,0
}
    80001e30:	60e2                	ld	ra,24(sp)
    80001e32:	6442                	ld	s0,16(sp)
    80001e34:	64a2                	ld	s1,8(sp)
    80001e36:	6902                	ld	s2,0(sp)
    80001e38:	6105                	addi	sp,sp,32
    80001e3a:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001e3c:	4691                	li	a3,4
    80001e3e:	00b90633          	add	a2,s2,a1
    80001e42:	6928                	ld	a0,80(a0)
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	636080e7          	jalr	1590(ra) # 8000147a <uvmalloc>
    80001e4c:	85aa                	mv	a1,a0
    80001e4e:	fd79                	bnez	a0,80001e2c <growproc+0x22>
      return -1;
    80001e50:	557d                	li	a0,-1
    80001e52:	bff9                	j	80001e30 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e54:	00b90633          	add	a2,s2,a1
    80001e58:	6928                	ld	a0,80(a0)
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	5d8080e7          	jalr	1496(ra) # 80001432 <uvmdealloc>
    80001e62:	85aa                	mv	a1,a0
    80001e64:	b7e1                	j	80001e2c <growproc+0x22>

0000000080001e66 <fork>:
{
    80001e66:	7139                	addi	sp,sp,-64
    80001e68:	fc06                	sd	ra,56(sp)
    80001e6a:	f822                	sd	s0,48(sp)
    80001e6c:	f04a                	sd	s2,32(sp)
    80001e6e:	e456                	sd	s5,8(sp)
    80001e70:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e72:	00000097          	auipc	ra,0x0
    80001e76:	bd8080e7          	jalr	-1064(ra) # 80001a4a <myproc>
    80001e7a:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001e7c:	00000097          	auipc	ra,0x0
    80001e80:	dd8080e7          	jalr	-552(ra) # 80001c54 <allocproc>
    80001e84:	12050463          	beqz	a0,80001fac <fork+0x146>
    80001e88:	ec4e                	sd	s3,24(sp)
    80001e8a:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001e8c:	048ab603          	ld	a2,72(s5)
    80001e90:	692c                	ld	a1,80(a0)
    80001e92:	050ab503          	ld	a0,80(s5)
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	748080e7          	jalr	1864(ra) # 800015de <uvmcopy>
    80001e9e:	04054e63          	bltz	a0,80001efa <fork+0x94>
    80001ea2:	f426                	sd	s1,40(sp)
    80001ea4:	e852                	sd	s4,16(sp)
  np->sz = p->sz;
    80001ea6:	048ab783          	ld	a5,72(s5)
    80001eaa:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001eae:	058ab683          	ld	a3,88(s5)
    80001eb2:	87b6                	mv	a5,a3
    80001eb4:	0589b703          	ld	a4,88(s3)
    80001eb8:	12068693          	addi	a3,a3,288
    80001ebc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ec0:	6788                	ld	a0,8(a5)
    80001ec2:	6b8c                	ld	a1,16(a5)
    80001ec4:	6f90                	ld	a2,24(a5)
    80001ec6:	01073023          	sd	a6,0(a4)
    80001eca:	e708                	sd	a0,8(a4)
    80001ecc:	eb0c                	sd	a1,16(a4)
    80001ece:	ef10                	sd	a2,24(a4)
    80001ed0:	02078793          	addi	a5,a5,32
    80001ed4:	02070713          	addi	a4,a4,32
    80001ed8:	fed792e3          	bne	a5,a3,80001ebc <fork+0x56>
  np->trapframe->a0 = 0;
    80001edc:	0589b783          	ld	a5,88(s3)
    80001ee0:	0607b823          	sd	zero,112(a5)
  np->tickets = p->tickets;
    80001ee4:	20caa783          	lw	a5,524(s5)
    80001ee8:	20f9a623          	sw	a5,524(s3)
  for (i = 0; i < NOFILE; i++)
    80001eec:	0d0a8493          	addi	s1,s5,208
    80001ef0:	0d098913          	addi	s2,s3,208
    80001ef4:	150a8a13          	addi	s4,s5,336
    80001ef8:	a015                	j	80001f1c <fork+0xb6>
    freeproc(np);
    80001efa:	854e                	mv	a0,s3
    80001efc:	00000097          	auipc	ra,0x0
    80001f00:	d00080e7          	jalr	-768(ra) # 80001bfc <freeproc>
    release(&np->lock);
    80001f04:	854e                	mv	a0,s3
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	de6080e7          	jalr	-538(ra) # 80000cec <release>
    return -1;
    80001f0e:	597d                	li	s2,-1
    80001f10:	69e2                	ld	s3,24(sp)
    80001f12:	a071                	j	80001f9e <fork+0x138>
  for (i = 0; i < NOFILE; i++)
    80001f14:	04a1                	addi	s1,s1,8
    80001f16:	0921                	addi	s2,s2,8
    80001f18:	01448b63          	beq	s1,s4,80001f2e <fork+0xc8>
    if (p->ofile[i])
    80001f1c:	6088                	ld	a0,0(s1)
    80001f1e:	d97d                	beqz	a0,80001f14 <fork+0xae>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f20:	00003097          	auipc	ra,0x3
    80001f24:	c32080e7          	jalr	-974(ra) # 80004b52 <filedup>
    80001f28:	00a93023          	sd	a0,0(s2)
    80001f2c:	b7e5                	j	80001f14 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001f2e:	150ab503          	ld	a0,336(s5)
    80001f32:	00002097          	auipc	ra,0x2
    80001f36:	d9c080e7          	jalr	-612(ra) # 80003cce <idup>
    80001f3a:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f3e:	4641                	li	a2,16
    80001f40:	158a8593          	addi	a1,s5,344
    80001f44:	15898513          	addi	a0,s3,344
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	f2e080e7          	jalr	-210(ra) # 80000e76 <safestrcpy>
  pid = np->pid;
    80001f50:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001f54:	854e                	mv	a0,s3
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	d96080e7          	jalr	-618(ra) # 80000cec <release>
  acquire(&wait_lock);
    80001f5e:	00011497          	auipc	s1,0x11
    80001f62:	6da48493          	addi	s1,s1,1754 # 80013638 <wait_lock>
    80001f66:	8526                	mv	a0,s1
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	cd0080e7          	jalr	-816(ra) # 80000c38 <acquire>
  np->parent = p;
    80001f70:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001f74:	8526                	mv	a0,s1
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	d76080e7          	jalr	-650(ra) # 80000cec <release>
  acquire(&np->lock);
    80001f7e:	854e                	mv	a0,s3
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	cb8080e7          	jalr	-840(ra) # 80000c38 <acquire>
  np->state = RUNNABLE;
    80001f88:	478d                	li	a5,3
    80001f8a:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f8e:	854e                	mv	a0,s3
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	d5c080e7          	jalr	-676(ra) # 80000cec <release>
  return pid;
    80001f98:	74a2                	ld	s1,40(sp)
    80001f9a:	69e2                	ld	s3,24(sp)
    80001f9c:	6a42                	ld	s4,16(sp)
}
    80001f9e:	854a                	mv	a0,s2
    80001fa0:	70e2                	ld	ra,56(sp)
    80001fa2:	7442                	ld	s0,48(sp)
    80001fa4:	7902                	ld	s2,32(sp)
    80001fa6:	6aa2                	ld	s5,8(sp)
    80001fa8:	6121                	addi	sp,sp,64
    80001faa:	8082                	ret
    return -1;
    80001fac:	597d                	li	s2,-1
    80001fae:	bfc5                	j	80001f9e <fork+0x138>

0000000080001fb0 <random_at_most>:
random_at_most(unsigned int max) {
    80001fb0:	1141                	addi	sp,sp,-16
    80001fb2:	e422                	sd	s0,8(sp)
    80001fb4:	0800                	addi	s0,sp,16
  seed = (1103515245 * seed + 12345) % 0x7fffffff;
    80001fb6:	00009697          	auipc	a3,0x9
    80001fba:	35e68693          	addi	a3,a3,862 # 8000b314 <seed.2>
    80001fbe:	4298                	lw	a4,0(a3)
    80001fc0:	41c657b7          	lui	a5,0x41c65
    80001fc4:	e6d7879b          	addiw	a5,a5,-403 # 41c64e6d <_entry-0x3e39b193>
    80001fc8:	02e787bb          	mulw	a5,a5,a4
    80001fcc:	670d                	lui	a4,0x3
    80001fce:	0397071b          	addiw	a4,a4,57 # 3039 <_entry-0x7fffcfc7>
    80001fd2:	9fb9                	addw	a5,a5,a4
    80001fd4:	80000737          	lui	a4,0x80000
    80001fd8:	377d                	addiw	a4,a4,-1 # 7fffffff <_entry-0x1>
    80001fda:	02e7f7bb          	remuw	a5,a5,a4
    80001fde:	c29c                	sw	a5,0(a3)
  return (seed % max) + 1;
    80001fe0:	02a7f53b          	remuw	a0,a5,a0
}
    80001fe4:	2505                	addiw	a0,a0,1
    80001fe6:	6422                	ld	s0,8(sp)
    80001fe8:	0141                	addi	sp,sp,16
    80001fea:	8082                	ret

0000000080001fec <scheduler>:
{
    80001fec:	711d                	addi	sp,sp,-96
    80001fee:	ec86                	sd	ra,88(sp)
    80001ff0:	e8a2                	sd	s0,80(sp)
    80001ff2:	e4a6                	sd	s1,72(sp)
    80001ff4:	e0ca                	sd	s2,64(sp)
    80001ff6:	fc4e                	sd	s3,56(sp)
    80001ff8:	f852                	sd	s4,48(sp)
    80001ffa:	f456                	sd	s5,40(sp)
    80001ffc:	f05a                	sd	s6,32(sp)
    80001ffe:	ec5e                	sd	s7,24(sp)
    80002000:	e862                	sd	s8,16(sp)
    80002002:	e466                	sd	s9,8(sp)
    80002004:	1080                	addi	s0,sp,96
    80002006:	8792                	mv	a5,tp
  int id = r_tp();
    80002008:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000200a:	00779b93          	slli	s7,a5,0x7
    8000200e:	00011717          	auipc	a4,0x11
    80002012:	61270713          	addi	a4,a4,1554 # 80013620 <pid_lock>
    80002016:	975e                	add	a4,a4,s7
    80002018:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &selected_proc->context);  // Context switch to process
    8000201c:	00011717          	auipc	a4,0x11
    80002020:	63c70713          	addi	a4,a4,1596 # 80013658 <cpus+0x8>
    80002024:	9bba                	add	s7,s7,a4
  p = 0, ticks_since_last_boost = 0;
    80002026:	4c01                	li	s8,0
        if (p->state == RUNNABLE)
    80002028:	490d                	li	s2,3
      for (p = proc; p < &proc[NPROC]; p++)
    8000202a:	0001a997          	auipc	s3,0x1a
    8000202e:	22698993          	addi	s3,s3,550 # 8001c250 <tickslock>
      ticks_since_last_boost = 0;  // Reset the boost timer
    80002032:	4b01                	li	s6,0
          printf("pid %d queue %d\n", p->pid, p->priority);
    80002034:	00006a17          	auipc	s4,0x6
    80002038:	1c4a0a13          	addi	s4,s4,452 # 800081f8 <etext+0x1f8>
      c->proc = selected_proc;  // Assign process to the CPU
    8000203c:	079e                	slli	a5,a5,0x7
    8000203e:	00011a97          	auipc	s5,0x11
    80002042:	5e2a8a93          	addi	s5,s5,1506 # 80013620 <pid_lock>
    80002046:	9abe                	add	s5,s5,a5
    80002048:	a0f5                	j	80002134 <scheduler+0x148>
      for (p = proc; p < &proc[NPROC]; p++)
    8000204a:	00012497          	auipc	s1,0x12
    8000204e:	a0648493          	addi	s1,s1,-1530 # 80013a50 <proc>
          p->time_slices = 1;
    80002052:	4c05                	li	s8,1
    80002054:	a811                	j	80002068 <scheduler+0x7c>
        release(&p->lock);
    80002056:	8526                	mv	a0,s1
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	c94080e7          	jalr	-876(ra) # 80000cec <release>
      for (p = proc; p < &proc[NPROC]; p++)
    80002060:	22048493          	addi	s1,s1,544
    80002064:	03348163          	beq	s1,s3,80002086 <scheduler+0x9a>
        acquire(&p->lock);
    80002068:	8526                	mv	a0,s1
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	bce080e7          	jalr	-1074(ra) # 80000c38 <acquire>
        if (p->state == RUNNABLE)
    80002072:	4c9c                	lw	a5,24(s1)
    80002074:	ff2791e3          	bne	a5,s2,80002056 <scheduler+0x6a>
          p->priority = 0;
    80002078:	2004aa23          	sw	zero,532(s1)
          p->ticks_in_level = 0;
    8000207c:	2004ae23          	sw	zero,540(s1)
          p->time_slices = 1;
    80002080:	2184ac23          	sw	s8,536(s1)
    80002084:	bfc9                	j	80002056 <scheduler+0x6a>
      ticks_since_last_boost = 0;  // Reset the boost timer
    80002086:	8c5a                	mv	s8,s6
    80002088:	a0c1                	j	80002148 <scheduler+0x15c>
        release(&p->lock);
    8000208a:	8526                	mv	a0,s1
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	c60080e7          	jalr	-928(ra) # 80000cec <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002094:	22048493          	addi	s1,s1,544
    80002098:	03348363          	beq	s1,s3,800020be <scheduler+0xd2>
        acquire(&p->lock);
    8000209c:	8526                	mv	a0,s1
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	b9a080e7          	jalr	-1126(ra) # 80000c38 <acquire>
        if (p->state == RUNNABLE)
    800020a6:	4c9c                	lw	a5,24(s1)
    800020a8:	ff2791e3          	bne	a5,s2,8000208a <scheduler+0x9e>
          printf("pid %d queue %d\n", p->pid, p->priority);
    800020ac:	2144a603          	lw	a2,532(s1)
    800020b0:	588c                	lw	a1,48(s1)
    800020b2:	8552                	mv	a0,s4
    800020b4:	ffffe097          	auipc	ra,0xffffe
    800020b8:	4f6080e7          	jalr	1270(ra) # 800005aa <printf>
    800020bc:	b7f9                	j	8000208a <scheduler+0x9e>
    for (int prio = 0; prio < 4; prio++) {  // Iterate through priority levels
    800020be:	8cda                	mv	s9,s6
        for (p = proc; p < &proc[NPROC]; p++) {
    800020c0:	00012497          	auipc	s1,0x12
    800020c4:	99048493          	addi	s1,s1,-1648 # 80013a50 <proc>
    800020c8:	a811                	j	800020dc <scheduler+0xf0>
            release(&p->lock);  // Release lock if this process is not selected
    800020ca:	8526                	mv	a0,s1
    800020cc:	fffff097          	auipc	ra,0xfffff
    800020d0:	c20080e7          	jalr	-992(ra) # 80000cec <release>
        for (p = proc; p < &proc[NPROC]; p++) {
    800020d4:	22048493          	addi	s1,s1,544
    800020d8:	07348d63          	beq	s1,s3,80002152 <scheduler+0x166>
            acquire(&p->lock);  // Acquire lock for each process
    800020dc:	8526                	mv	a0,s1
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	b5a080e7          	jalr	-1190(ra) # 80000c38 <acquire>
            if (p->state == RUNNABLE && p->priority == prio) {
    800020e6:	4c9c                	lw	a5,24(s1)
    800020e8:	ff2791e3          	bne	a5,s2,800020ca <scheduler+0xde>
    800020ec:	2144a783          	lw	a5,532(s1)
    800020f0:	fd979de3          	bne	a5,s9,800020ca <scheduler+0xde>
      selected_proc->state = RUNNING;
    800020f4:	4791                	li	a5,4
    800020f6:	cc9c                	sw	a5,24(s1)
      c->proc = selected_proc;  // Assign process to the CPU
    800020f8:	029ab823          	sd	s1,48(s5)
      swtch(&c->context, &selected_proc->context);  // Context switch to process
    800020fc:	06048593          	addi	a1,s1,96
    80002100:	855e                	mv	a0,s7
    80002102:	00001097          	auipc	ra,0x1
    80002106:	95c080e7          	jalr	-1700(ra) # 80002a5e <swtch>
      c->proc = 0;
    8000210a:	020ab823          	sd	zero,48(s5)
      selected_proc->ticks_in_level++;
    8000210e:	21c4a783          	lw	a5,540(s1)
    80002112:	2785                	addiw	a5,a5,1
    80002114:	20f4ae23          	sw	a5,540(s1)
      selected_proc->time_slices--;
    80002118:	2184a783          	lw	a5,536(s1)
    8000211c:	37fd                	addiw	a5,a5,-1
    8000211e:	0007871b          	sext.w	a4,a5
    80002122:	20f4ac23          	sw	a5,536(s1)
      if (selected_proc->time_slices == 0) {
    80002126:	cb1d                	beqz	a4,8000215c <scheduler+0x170>
      release(&selected_proc->lock);  // Release lock after process demotion logic
    80002128:	8526                	mv	a0,s1
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	bc2080e7          	jalr	-1086(ra) # 80000cec <release>
    ticks_since_last_boost++;
    80002132:	2c05                	addiw	s8,s8,1
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002134:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002138:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000213c:	10079073          	csrw	sstatus,a5
    if (ticks_since_last_boost >= boost_ticks)
    80002140:	02f00793          	li	a5,47
    80002144:	f187c3e3          	blt	a5,s8,8000204a <scheduler+0x5e>
    for (p = proc; p < &proc[NPROC]; p++)
    80002148:	00012497          	auipc	s1,0x12
    8000214c:	90848493          	addi	s1,s1,-1784 # 80013a50 <proc>
    80002150:	b7b1                	j	8000209c <scheduler+0xb0>
    for (int prio = 0; prio < 4; prio++) {  // Iterate through priority levels
    80002152:	2c85                	addiw	s9,s9,1
    80002154:	4791                	li	a5,4
    80002156:	f6fc95e3          	bne	s9,a5,800020c0 <scheduler+0xd4>
    8000215a:	bfe1                	j	80002132 <scheduler+0x146>
        if (selected_proc->priority < 3) {
    8000215c:	2144a783          	lw	a5,532(s1)
    80002160:	4709                	li	a4,2
    80002162:	02f74063          	blt	a4,a5,80002182 <scheduler+0x196>
            selected_proc->priority++;  // Demote to the next lower priority
    80002166:	2785                	addiw	a5,a5,1
    80002168:	20f4aa23          	sw	a5,532(s1)
        switch (selected_proc->priority) {
    8000216c:	2781                	sext.w	a5,a5
    8000216e:	00e79c63          	bne	a5,a4,80002186 <scheduler+0x19a>
            selected_proc->time_slices = 8;  // Time slice for priority 2
    80002172:	47a1                	li	a5,8
    80002174:	20f4ac23          	sw	a5,536(s1)
            break;
    80002178:	bf45                	j	80002128 <scheduler+0x13c>
            selected_proc->time_slices = 16;  // Time slice for priority 3
    8000217a:	47c1                	li	a5,16
    8000217c:	20f4ac23          	sw	a5,536(s1)
            break;
    80002180:	b765                	j	80002128 <scheduler+0x13c>
        switch (selected_proc->priority) {
    80002182:	2144a783          	lw	a5,532(s1)
    80002186:	ff278ae3          	beq	a5,s2,8000217a <scheduler+0x18e>
    8000218a:	4705                	li	a4,1
    8000218c:	f8e79ee3          	bne	a5,a4,80002128 <scheduler+0x13c>
            selected_proc->time_slices = 4;  // Time slice for priority 1
    80002190:	4791                	li	a5,4
    80002192:	20f4ac23          	sw	a5,536(s1)
            break;
    80002196:	bf49                	j	80002128 <scheduler+0x13c>

0000000080002198 <sched>:
{
    80002198:	7179                	addi	sp,sp,-48
    8000219a:	f406                	sd	ra,40(sp)
    8000219c:	f022                	sd	s0,32(sp)
    8000219e:	ec26                	sd	s1,24(sp)
    800021a0:	e84a                	sd	s2,16(sp)
    800021a2:	e44e                	sd	s3,8(sp)
    800021a4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021a6:	00000097          	auipc	ra,0x0
    800021aa:	8a4080e7          	jalr	-1884(ra) # 80001a4a <myproc>
    800021ae:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	a0e080e7          	jalr	-1522(ra) # 80000bbe <holding>
    800021b8:	c93d                	beqz	a0,8000222e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021ba:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800021bc:	2781                	sext.w	a5,a5
    800021be:	079e                	slli	a5,a5,0x7
    800021c0:	00011717          	auipc	a4,0x11
    800021c4:	46070713          	addi	a4,a4,1120 # 80013620 <pid_lock>
    800021c8:	97ba                	add	a5,a5,a4
    800021ca:	0a87a703          	lw	a4,168(a5)
    800021ce:	4785                	li	a5,1
    800021d0:	06f71763          	bne	a4,a5,8000223e <sched+0xa6>
  if (p->state == RUNNING)
    800021d4:	4c98                	lw	a4,24(s1)
    800021d6:	4791                	li	a5,4
    800021d8:	06f70b63          	beq	a4,a5,8000224e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021dc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021e0:	8b89                	andi	a5,a5,2
  if (intr_get())
    800021e2:	efb5                	bnez	a5,8000225e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021e4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021e6:	00011917          	auipc	s2,0x11
    800021ea:	43a90913          	addi	s2,s2,1082 # 80013620 <pid_lock>
    800021ee:	2781                	sext.w	a5,a5
    800021f0:	079e                	slli	a5,a5,0x7
    800021f2:	97ca                	add	a5,a5,s2
    800021f4:	0ac7a983          	lw	s3,172(a5)
    800021f8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021fa:	2781                	sext.w	a5,a5
    800021fc:	079e                	slli	a5,a5,0x7
    800021fe:	00011597          	auipc	a1,0x11
    80002202:	45a58593          	addi	a1,a1,1114 # 80013658 <cpus+0x8>
    80002206:	95be                	add	a1,a1,a5
    80002208:	06048513          	addi	a0,s1,96
    8000220c:	00001097          	auipc	ra,0x1
    80002210:	852080e7          	jalr	-1966(ra) # 80002a5e <swtch>
    80002214:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002216:	2781                	sext.w	a5,a5
    80002218:	079e                	slli	a5,a5,0x7
    8000221a:	993e                	add	s2,s2,a5
    8000221c:	0b392623          	sw	s3,172(s2)
}
    80002220:	70a2                	ld	ra,40(sp)
    80002222:	7402                	ld	s0,32(sp)
    80002224:	64e2                	ld	s1,24(sp)
    80002226:	6942                	ld	s2,16(sp)
    80002228:	69a2                	ld	s3,8(sp)
    8000222a:	6145                	addi	sp,sp,48
    8000222c:	8082                	ret
    panic("sched p->lock");
    8000222e:	00006517          	auipc	a0,0x6
    80002232:	fe250513          	addi	a0,a0,-30 # 80008210 <etext+0x210>
    80002236:	ffffe097          	auipc	ra,0xffffe
    8000223a:	32a080e7          	jalr	810(ra) # 80000560 <panic>
    panic("sched locks");
    8000223e:	00006517          	auipc	a0,0x6
    80002242:	fe250513          	addi	a0,a0,-30 # 80008220 <etext+0x220>
    80002246:	ffffe097          	auipc	ra,0xffffe
    8000224a:	31a080e7          	jalr	794(ra) # 80000560 <panic>
    panic("sched running");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	fe250513          	addi	a0,a0,-30 # 80008230 <etext+0x230>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	30a080e7          	jalr	778(ra) # 80000560 <panic>
    panic("sched interruptible");
    8000225e:	00006517          	auipc	a0,0x6
    80002262:	fe250513          	addi	a0,a0,-30 # 80008240 <etext+0x240>
    80002266:	ffffe097          	auipc	ra,0xffffe
    8000226a:	2fa080e7          	jalr	762(ra) # 80000560 <panic>

000000008000226e <yield>:
{
    8000226e:	1101                	addi	sp,sp,-32
    80002270:	ec06                	sd	ra,24(sp)
    80002272:	e822                	sd	s0,16(sp)
    80002274:	e426                	sd	s1,8(sp)
    80002276:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	7d2080e7          	jalr	2002(ra) # 80001a4a <myproc>
    80002280:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	9b6080e7          	jalr	-1610(ra) # 80000c38 <acquire>
  p->ticks_in_level = 0;
    8000228a:	2004ae23          	sw	zero,540(s1)
  p->state = RUNNABLE;
    8000228e:	478d                	li	a5,3
    80002290:	cc9c                	sw	a5,24(s1)
  sched();
    80002292:	00000097          	auipc	ra,0x0
    80002296:	f06080e7          	jalr	-250(ra) # 80002198 <sched>
  release(&p->lock);
    8000229a:	8526                	mv	a0,s1
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	a50080e7          	jalr	-1456(ra) # 80000cec <release>
}
    800022a4:	60e2                	ld	ra,24(sp)
    800022a6:	6442                	ld	s0,16(sp)
    800022a8:	64a2                	ld	s1,8(sp)
    800022aa:	6105                	addi	sp,sp,32
    800022ac:	8082                	ret

00000000800022ae <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800022ae:	7179                	addi	sp,sp,-48
    800022b0:	f406                	sd	ra,40(sp)
    800022b2:	f022                	sd	s0,32(sp)
    800022b4:	ec26                	sd	s1,24(sp)
    800022b6:	e84a                	sd	s2,16(sp)
    800022b8:	e44e                	sd	s3,8(sp)
    800022ba:	1800                	addi	s0,sp,48
    800022bc:	89aa                	mv	s3,a0
    800022be:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	78a080e7          	jalr	1930(ra) # 80001a4a <myproc>
    800022c8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	96e080e7          	jalr	-1682(ra) # 80000c38 <acquire>
  release(lk);
    800022d2:	854a                	mv	a0,s2
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	a18080e7          	jalr	-1512(ra) # 80000cec <release>

  // Go to sleep.
  p->chan = chan;
    800022dc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800022e0:	4789                	li	a5,2
    800022e2:	cc9c                	sw	a5,24(s1)

  sched();
    800022e4:	00000097          	auipc	ra,0x0
    800022e8:	eb4080e7          	jalr	-332(ra) # 80002198 <sched>

  // Tidy up.
  p->chan = 0;
    800022ec:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800022f0:	8526                	mv	a0,s1
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	9fa080e7          	jalr	-1542(ra) # 80000cec <release>
  acquire(lk);
    800022fa:	854a                	mv	a0,s2
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	93c080e7          	jalr	-1732(ra) # 80000c38 <acquire>
}
    80002304:	70a2                	ld	ra,40(sp)
    80002306:	7402                	ld	s0,32(sp)
    80002308:	64e2                	ld	s1,24(sp)
    8000230a:	6942                	ld	s2,16(sp)
    8000230c:	69a2                	ld	s3,8(sp)
    8000230e:	6145                	addi	sp,sp,48
    80002310:	8082                	ret

0000000080002312 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002312:	7139                	addi	sp,sp,-64
    80002314:	fc06                	sd	ra,56(sp)
    80002316:	f822                	sd	s0,48(sp)
    80002318:	f426                	sd	s1,40(sp)
    8000231a:	f04a                	sd	s2,32(sp)
    8000231c:	ec4e                	sd	s3,24(sp)
    8000231e:	e852                	sd	s4,16(sp)
    80002320:	e456                	sd	s5,8(sp)
    80002322:	0080                	addi	s0,sp,64
    80002324:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002326:	00011497          	auipc	s1,0x11
    8000232a:	72a48493          	addi	s1,s1,1834 # 80013a50 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000232e:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002330:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002332:	0001a917          	auipc	s2,0x1a
    80002336:	f1e90913          	addi	s2,s2,-226 # 8001c250 <tickslock>
    8000233a:	a811                	j	8000234e <wakeup+0x3c>
      }
      release(&p->lock);
    8000233c:	8526                	mv	a0,s1
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	9ae080e7          	jalr	-1618(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002346:	22048493          	addi	s1,s1,544
    8000234a:	03248663          	beq	s1,s2,80002376 <wakeup+0x64>
    if (p != myproc())
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	6fc080e7          	jalr	1788(ra) # 80001a4a <myproc>
    80002356:	fea488e3          	beq	s1,a0,80002346 <wakeup+0x34>
      acquire(&p->lock);
    8000235a:	8526                	mv	a0,s1
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	8dc080e7          	jalr	-1828(ra) # 80000c38 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002364:	4c9c                	lw	a5,24(s1)
    80002366:	fd379be3          	bne	a5,s3,8000233c <wakeup+0x2a>
    8000236a:	709c                	ld	a5,32(s1)
    8000236c:	fd4798e3          	bne	a5,s4,8000233c <wakeup+0x2a>
        p->state = RUNNABLE;
    80002370:	0154ac23          	sw	s5,24(s1)
    80002374:	b7e1                	j	8000233c <wakeup+0x2a>
    }
  }
}
    80002376:	70e2                	ld	ra,56(sp)
    80002378:	7442                	ld	s0,48(sp)
    8000237a:	74a2                	ld	s1,40(sp)
    8000237c:	7902                	ld	s2,32(sp)
    8000237e:	69e2                	ld	s3,24(sp)
    80002380:	6a42                	ld	s4,16(sp)
    80002382:	6aa2                	ld	s5,8(sp)
    80002384:	6121                	addi	sp,sp,64
    80002386:	8082                	ret

0000000080002388 <reparent>:
{
    80002388:	7179                	addi	sp,sp,-48
    8000238a:	f406                	sd	ra,40(sp)
    8000238c:	f022                	sd	s0,32(sp)
    8000238e:	ec26                	sd	s1,24(sp)
    80002390:	e84a                	sd	s2,16(sp)
    80002392:	e44e                	sd	s3,8(sp)
    80002394:	e052                	sd	s4,0(sp)
    80002396:	1800                	addi	s0,sp,48
    80002398:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000239a:	00011497          	auipc	s1,0x11
    8000239e:	6b648493          	addi	s1,s1,1718 # 80013a50 <proc>
      pp->parent = initproc;
    800023a2:	00009a17          	auipc	s4,0x9
    800023a6:	006a0a13          	addi	s4,s4,6 # 8000b3a8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800023aa:	0001a997          	auipc	s3,0x1a
    800023ae:	ea698993          	addi	s3,s3,-346 # 8001c250 <tickslock>
    800023b2:	a029                	j	800023bc <reparent+0x34>
    800023b4:	22048493          	addi	s1,s1,544
    800023b8:	01348d63          	beq	s1,s3,800023d2 <reparent+0x4a>
    if (pp->parent == p)
    800023bc:	7c9c                	ld	a5,56(s1)
    800023be:	ff279be3          	bne	a5,s2,800023b4 <reparent+0x2c>
      pp->parent = initproc;
    800023c2:	000a3503          	ld	a0,0(s4)
    800023c6:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800023c8:	00000097          	auipc	ra,0x0
    800023cc:	f4a080e7          	jalr	-182(ra) # 80002312 <wakeup>
    800023d0:	b7d5                	j	800023b4 <reparent+0x2c>
}
    800023d2:	70a2                	ld	ra,40(sp)
    800023d4:	7402                	ld	s0,32(sp)
    800023d6:	64e2                	ld	s1,24(sp)
    800023d8:	6942                	ld	s2,16(sp)
    800023da:	69a2                	ld	s3,8(sp)
    800023dc:	6a02                	ld	s4,0(sp)
    800023de:	6145                	addi	sp,sp,48
    800023e0:	8082                	ret

00000000800023e2 <exit>:
{
    800023e2:	7179                	addi	sp,sp,-48
    800023e4:	f406                	sd	ra,40(sp)
    800023e6:	f022                	sd	s0,32(sp)
    800023e8:	ec26                	sd	s1,24(sp)
    800023ea:	e84a                	sd	s2,16(sp)
    800023ec:	e44e                	sd	s3,8(sp)
    800023ee:	e052                	sd	s4,0(sp)
    800023f0:	1800                	addi	s0,sp,48
    800023f2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	656080e7          	jalr	1622(ra) # 80001a4a <myproc>
    800023fc:	89aa                	mv	s3,a0
  if (p == initproc)
    800023fe:	00009797          	auipc	a5,0x9
    80002402:	faa7b783          	ld	a5,-86(a5) # 8000b3a8 <initproc>
    80002406:	0d050493          	addi	s1,a0,208
    8000240a:	15050913          	addi	s2,a0,336
    8000240e:	02a79363          	bne	a5,a0,80002434 <exit+0x52>
    panic("init exiting");
    80002412:	00006517          	auipc	a0,0x6
    80002416:	e4650513          	addi	a0,a0,-442 # 80008258 <etext+0x258>
    8000241a:	ffffe097          	auipc	ra,0xffffe
    8000241e:	146080e7          	jalr	326(ra) # 80000560 <panic>
      fileclose(f);
    80002422:	00002097          	auipc	ra,0x2
    80002426:	782080e7          	jalr	1922(ra) # 80004ba4 <fileclose>
      p->ofile[fd] = 0;
    8000242a:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000242e:	04a1                	addi	s1,s1,8
    80002430:	01248563          	beq	s1,s2,8000243a <exit+0x58>
    if (p->ofile[fd])
    80002434:	6088                	ld	a0,0(s1)
    80002436:	f575                	bnez	a0,80002422 <exit+0x40>
    80002438:	bfdd                	j	8000242e <exit+0x4c>
  begin_op();
    8000243a:	00002097          	auipc	ra,0x2
    8000243e:	2a0080e7          	jalr	672(ra) # 800046da <begin_op>
  iput(p->cwd);
    80002442:	1509b503          	ld	a0,336(s3)
    80002446:	00002097          	auipc	ra,0x2
    8000244a:	a84080e7          	jalr	-1404(ra) # 80003eca <iput>
  end_op();
    8000244e:	00002097          	auipc	ra,0x2
    80002452:	306080e7          	jalr	774(ra) # 80004754 <end_op>
  p->cwd = 0;
    80002456:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000245a:	00011497          	auipc	s1,0x11
    8000245e:	1de48493          	addi	s1,s1,478 # 80013638 <wait_lock>
    80002462:	8526                	mv	a0,s1
    80002464:	ffffe097          	auipc	ra,0xffffe
    80002468:	7d4080e7          	jalr	2004(ra) # 80000c38 <acquire>
  reparent(p);
    8000246c:	854e                	mv	a0,s3
    8000246e:	00000097          	auipc	ra,0x0
    80002472:	f1a080e7          	jalr	-230(ra) # 80002388 <reparent>
  wakeup(p->parent);
    80002476:	0389b503          	ld	a0,56(s3)
    8000247a:	00000097          	auipc	ra,0x0
    8000247e:	e98080e7          	jalr	-360(ra) # 80002312 <wakeup>
  acquire(&p->lock);
    80002482:	854e                	mv	a0,s3
    80002484:	ffffe097          	auipc	ra,0xffffe
    80002488:	7b4080e7          	jalr	1972(ra) # 80000c38 <acquire>
  p->xstate = status;
    8000248c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002490:	4795                	li	a5,5
    80002492:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002496:	00009797          	auipc	a5,0x9
    8000249a:	f1a7a783          	lw	a5,-230(a5) # 8000b3b0 <ticks>
    8000249e:	16f9a823          	sw	a5,368(s3)
  kfree(p->original_trapframe);
    800024a2:	2009b503          	ld	a0,512(s3)
    800024a6:	ffffe097          	auipc	ra,0xffffe
    800024aa:	5a4080e7          	jalr	1444(ra) # 80000a4a <kfree>
  release(&wait_lock);
    800024ae:	8526                	mv	a0,s1
    800024b0:	fffff097          	auipc	ra,0xfffff
    800024b4:	83c080e7          	jalr	-1988(ra) # 80000cec <release>
  sched();
    800024b8:	00000097          	auipc	ra,0x0
    800024bc:	ce0080e7          	jalr	-800(ra) # 80002198 <sched>
  panic("zombie exit");
    800024c0:	00006517          	auipc	a0,0x6
    800024c4:	da850513          	addi	a0,a0,-600 # 80008268 <etext+0x268>
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	098080e7          	jalr	152(ra) # 80000560 <panic>

00000000800024d0 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800024d0:	7179                	addi	sp,sp,-48
    800024d2:	f406                	sd	ra,40(sp)
    800024d4:	f022                	sd	s0,32(sp)
    800024d6:	ec26                	sd	s1,24(sp)
    800024d8:	e84a                	sd	s2,16(sp)
    800024da:	e44e                	sd	s3,8(sp)
    800024dc:	1800                	addi	s0,sp,48
    800024de:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800024e0:	00011497          	auipc	s1,0x11
    800024e4:	57048493          	addi	s1,s1,1392 # 80013a50 <proc>
    800024e8:	0001a997          	auipc	s3,0x1a
    800024ec:	d6898993          	addi	s3,s3,-664 # 8001c250 <tickslock>
  {
    acquire(&p->lock);
    800024f0:	8526                	mv	a0,s1
    800024f2:	ffffe097          	auipc	ra,0xffffe
    800024f6:	746080e7          	jalr	1862(ra) # 80000c38 <acquire>
    if (p->pid == pid)
    800024fa:	589c                	lw	a5,48(s1)
    800024fc:	01278d63          	beq	a5,s2,80002516 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002500:	8526                	mv	a0,s1
    80002502:	ffffe097          	auipc	ra,0xffffe
    80002506:	7ea080e7          	jalr	2026(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000250a:	22048493          	addi	s1,s1,544
    8000250e:	ff3491e3          	bne	s1,s3,800024f0 <kill+0x20>
  }
  return -1;
    80002512:	557d                	li	a0,-1
    80002514:	a829                	j	8000252e <kill+0x5e>
      p->killed = 1;
    80002516:	4785                	li	a5,1
    80002518:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000251a:	4c98                	lw	a4,24(s1)
    8000251c:	4789                	li	a5,2
    8000251e:	00f70f63          	beq	a4,a5,8000253c <kill+0x6c>
      release(&p->lock);
    80002522:	8526                	mv	a0,s1
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	7c8080e7          	jalr	1992(ra) # 80000cec <release>
      return 0;
    8000252c:	4501                	li	a0,0
}
    8000252e:	70a2                	ld	ra,40(sp)
    80002530:	7402                	ld	s0,32(sp)
    80002532:	64e2                	ld	s1,24(sp)
    80002534:	6942                	ld	s2,16(sp)
    80002536:	69a2                	ld	s3,8(sp)
    80002538:	6145                	addi	sp,sp,48
    8000253a:	8082                	ret
        p->state = RUNNABLE;
    8000253c:	478d                	li	a5,3
    8000253e:	cc9c                	sw	a5,24(s1)
    80002540:	b7cd                	j	80002522 <kill+0x52>

0000000080002542 <setkilled>:

void setkilled(struct proc *p)
{
    80002542:	1101                	addi	sp,sp,-32
    80002544:	ec06                	sd	ra,24(sp)
    80002546:	e822                	sd	s0,16(sp)
    80002548:	e426                	sd	s1,8(sp)
    8000254a:	1000                	addi	s0,sp,32
    8000254c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000254e:	ffffe097          	auipc	ra,0xffffe
    80002552:	6ea080e7          	jalr	1770(ra) # 80000c38 <acquire>
  p->killed = 1;
    80002556:	4785                	li	a5,1
    80002558:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000255a:	8526                	mv	a0,s1
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	790080e7          	jalr	1936(ra) # 80000cec <release>
}
    80002564:	60e2                	ld	ra,24(sp)
    80002566:	6442                	ld	s0,16(sp)
    80002568:	64a2                	ld	s1,8(sp)
    8000256a:	6105                	addi	sp,sp,32
    8000256c:	8082                	ret

000000008000256e <killed>:

int killed(struct proc *p)
{
    8000256e:	1101                	addi	sp,sp,-32
    80002570:	ec06                	sd	ra,24(sp)
    80002572:	e822                	sd	s0,16(sp)
    80002574:	e426                	sd	s1,8(sp)
    80002576:	e04a                	sd	s2,0(sp)
    80002578:	1000                	addi	s0,sp,32
    8000257a:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	6bc080e7          	jalr	1724(ra) # 80000c38 <acquire>
  k = p->killed;
    80002584:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002588:	8526                	mv	a0,s1
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	762080e7          	jalr	1890(ra) # 80000cec <release>
  return k;
}
    80002592:	854a                	mv	a0,s2
    80002594:	60e2                	ld	ra,24(sp)
    80002596:	6442                	ld	s0,16(sp)
    80002598:	64a2                	ld	s1,8(sp)
    8000259a:	6902                	ld	s2,0(sp)
    8000259c:	6105                	addi	sp,sp,32
    8000259e:	8082                	ret

00000000800025a0 <wait>:
{
    800025a0:	715d                	addi	sp,sp,-80
    800025a2:	e486                	sd	ra,72(sp)
    800025a4:	e0a2                	sd	s0,64(sp)
    800025a6:	fc26                	sd	s1,56(sp)
    800025a8:	f84a                	sd	s2,48(sp)
    800025aa:	f44e                	sd	s3,40(sp)
    800025ac:	f052                	sd	s4,32(sp)
    800025ae:	ec56                	sd	s5,24(sp)
    800025b0:	e85a                	sd	s6,16(sp)
    800025b2:	e45e                	sd	s7,8(sp)
    800025b4:	e062                	sd	s8,0(sp)
    800025b6:	0880                	addi	s0,sp,80
    800025b8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800025ba:	fffff097          	auipc	ra,0xfffff
    800025be:	490080e7          	jalr	1168(ra) # 80001a4a <myproc>
    800025c2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800025c4:	00011517          	auipc	a0,0x11
    800025c8:	07450513          	addi	a0,a0,116 # 80013638 <wait_lock>
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	66c080e7          	jalr	1644(ra) # 80000c38 <acquire>
    havekids = 0;
    800025d4:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800025d6:	4a95                	li	s5,5
        havekids = 1;
    800025d8:	4b05                	li	s6,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025da:	0001a997          	auipc	s3,0x1a
    800025de:	c7698993          	addi	s3,s3,-906 # 8001c250 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800025e2:	00011c17          	auipc	s8,0x11
    800025e6:	056c0c13          	addi	s8,s8,86 # 80013638 <wait_lock>
    800025ea:	a0c5                	j	800026ca <wait+0x12a>
          pid = pp->pid;
    800025ec:	0304a983          	lw	s3,48(s1)
          for(int i=0; i<31; i++)
    800025f0:	17490793          	addi	a5,s2,372
    800025f4:	17448693          	addi	a3,s1,372
    800025f8:	1f090593          	addi	a1,s2,496
            p->syscall_count[i] += pp->syscall_count[i];
    800025fc:	4390                	lw	a2,0(a5)
    800025fe:	4298                	lw	a4,0(a3)
    80002600:	9f31                	addw	a4,a4,a2
    80002602:	c398                	sw	a4,0(a5)
          for(int i=0; i<31; i++)
    80002604:	0791                	addi	a5,a5,4
    80002606:	0691                	addi	a3,a3,4
    80002608:	feb79ae3          	bne	a5,a1,800025fc <wait+0x5c>
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000260c:	000a0e63          	beqz	s4,80002628 <wait+0x88>
    80002610:	4691                	li	a3,4
    80002612:	02c48613          	addi	a2,s1,44
    80002616:	85d2                	mv	a1,s4
    80002618:	05093503          	ld	a0,80(s2)
    8000261c:	fffff097          	auipc	ra,0xfffff
    80002620:	0c6080e7          	jalr	198(ra) # 800016e2 <copyout>
    80002624:	04054163          	bltz	a0,80002666 <wait+0xc6>
          freeproc(pp);
    80002628:	8526                	mv	a0,s1
    8000262a:	fffff097          	auipc	ra,0xfffff
    8000262e:	5d2080e7          	jalr	1490(ra) # 80001bfc <freeproc>
          release(&pp->lock);
    80002632:	8526                	mv	a0,s1
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	6b8080e7          	jalr	1720(ra) # 80000cec <release>
          release(&wait_lock);
    8000263c:	00011517          	auipc	a0,0x11
    80002640:	ffc50513          	addi	a0,a0,-4 # 80013638 <wait_lock>
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	6a8080e7          	jalr	1704(ra) # 80000cec <release>
}
    8000264c:	854e                	mv	a0,s3
    8000264e:	60a6                	ld	ra,72(sp)
    80002650:	6406                	ld	s0,64(sp)
    80002652:	74e2                	ld	s1,56(sp)
    80002654:	7942                	ld	s2,48(sp)
    80002656:	79a2                	ld	s3,40(sp)
    80002658:	7a02                	ld	s4,32(sp)
    8000265a:	6ae2                	ld	s5,24(sp)
    8000265c:	6b42                	ld	s6,16(sp)
    8000265e:	6ba2                	ld	s7,8(sp)
    80002660:	6c02                	ld	s8,0(sp)
    80002662:	6161                	addi	sp,sp,80
    80002664:	8082                	ret
            release(&pp->lock);
    80002666:	8526                	mv	a0,s1
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	684080e7          	jalr	1668(ra) # 80000cec <release>
            release(&wait_lock);
    80002670:	00011517          	auipc	a0,0x11
    80002674:	fc850513          	addi	a0,a0,-56 # 80013638 <wait_lock>
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	674080e7          	jalr	1652(ra) # 80000cec <release>
            return -1;
    80002680:	59fd                	li	s3,-1
    80002682:	b7e9                	j	8000264c <wait+0xac>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002684:	22048493          	addi	s1,s1,544
    80002688:	03348463          	beq	s1,s3,800026b0 <wait+0x110>
      if (pp->parent == p)
    8000268c:	7c9c                	ld	a5,56(s1)
    8000268e:	ff279be3          	bne	a5,s2,80002684 <wait+0xe4>
        acquire(&pp->lock);
    80002692:	8526                	mv	a0,s1
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	5a4080e7          	jalr	1444(ra) # 80000c38 <acquire>
        if (pp->state == ZOMBIE)
    8000269c:	4c9c                	lw	a5,24(s1)
    8000269e:	f55787e3          	beq	a5,s5,800025ec <wait+0x4c>
        release(&pp->lock);
    800026a2:	8526                	mv	a0,s1
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	648080e7          	jalr	1608(ra) # 80000cec <release>
        havekids = 1;
    800026ac:	875a                	mv	a4,s6
    800026ae:	bfd9                	j	80002684 <wait+0xe4>
    if (!havekids || killed(p))
    800026b0:	c31d                	beqz	a4,800026d6 <wait+0x136>
    800026b2:	854a                	mv	a0,s2
    800026b4:	00000097          	auipc	ra,0x0
    800026b8:	eba080e7          	jalr	-326(ra) # 8000256e <killed>
    800026bc:	ed09                	bnez	a0,800026d6 <wait+0x136>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026be:	85e2                	mv	a1,s8
    800026c0:	854a                	mv	a0,s2
    800026c2:	00000097          	auipc	ra,0x0
    800026c6:	bec080e7          	jalr	-1044(ra) # 800022ae <sleep>
    havekids = 0;
    800026ca:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026cc:	00011497          	auipc	s1,0x11
    800026d0:	38448493          	addi	s1,s1,900 # 80013a50 <proc>
    800026d4:	bf65                	j	8000268c <wait+0xec>
      release(&wait_lock);
    800026d6:	00011517          	auipc	a0,0x11
    800026da:	f6250513          	addi	a0,a0,-158 # 80013638 <wait_lock>
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	60e080e7          	jalr	1550(ra) # 80000cec <release>
      return -1;
    800026e6:	59fd                	li	s3,-1
    800026e8:	b795                	j	8000264c <wait+0xac>

00000000800026ea <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026ea:	7179                	addi	sp,sp,-48
    800026ec:	f406                	sd	ra,40(sp)
    800026ee:	f022                	sd	s0,32(sp)
    800026f0:	ec26                	sd	s1,24(sp)
    800026f2:	e84a                	sd	s2,16(sp)
    800026f4:	e44e                	sd	s3,8(sp)
    800026f6:	e052                	sd	s4,0(sp)
    800026f8:	1800                	addi	s0,sp,48
    800026fa:	84aa                	mv	s1,a0
    800026fc:	892e                	mv	s2,a1
    800026fe:	89b2                	mv	s3,a2
    80002700:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002702:	fffff097          	auipc	ra,0xfffff
    80002706:	348080e7          	jalr	840(ra) # 80001a4a <myproc>
  if (user_dst)
    8000270a:	c08d                	beqz	s1,8000272c <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000270c:	86d2                	mv	a3,s4
    8000270e:	864e                	mv	a2,s3
    80002710:	85ca                	mv	a1,s2
    80002712:	6928                	ld	a0,80(a0)
    80002714:	fffff097          	auipc	ra,0xfffff
    80002718:	fce080e7          	jalr	-50(ra) # 800016e2 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000271c:	70a2                	ld	ra,40(sp)
    8000271e:	7402                	ld	s0,32(sp)
    80002720:	64e2                	ld	s1,24(sp)
    80002722:	6942                	ld	s2,16(sp)
    80002724:	69a2                	ld	s3,8(sp)
    80002726:	6a02                	ld	s4,0(sp)
    80002728:	6145                	addi	sp,sp,48
    8000272a:	8082                	ret
    memmove((char *)dst, src, len);
    8000272c:	000a061b          	sext.w	a2,s4
    80002730:	85ce                	mv	a1,s3
    80002732:	854a                	mv	a0,s2
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	65c080e7          	jalr	1628(ra) # 80000d90 <memmove>
    return 0;
    8000273c:	8526                	mv	a0,s1
    8000273e:	bff9                	j	8000271c <either_copyout+0x32>

0000000080002740 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002740:	7179                	addi	sp,sp,-48
    80002742:	f406                	sd	ra,40(sp)
    80002744:	f022                	sd	s0,32(sp)
    80002746:	ec26                	sd	s1,24(sp)
    80002748:	e84a                	sd	s2,16(sp)
    8000274a:	e44e                	sd	s3,8(sp)
    8000274c:	e052                	sd	s4,0(sp)
    8000274e:	1800                	addi	s0,sp,48
    80002750:	892a                	mv	s2,a0
    80002752:	84ae                	mv	s1,a1
    80002754:	89b2                	mv	s3,a2
    80002756:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002758:	fffff097          	auipc	ra,0xfffff
    8000275c:	2f2080e7          	jalr	754(ra) # 80001a4a <myproc>
  if (user_src)
    80002760:	c08d                	beqz	s1,80002782 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002762:	86d2                	mv	a3,s4
    80002764:	864e                	mv	a2,s3
    80002766:	85ca                	mv	a1,s2
    80002768:	6928                	ld	a0,80(a0)
    8000276a:	fffff097          	auipc	ra,0xfffff
    8000276e:	004080e7          	jalr	4(ra) # 8000176e <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002772:	70a2                	ld	ra,40(sp)
    80002774:	7402                	ld	s0,32(sp)
    80002776:	64e2                	ld	s1,24(sp)
    80002778:	6942                	ld	s2,16(sp)
    8000277a:	69a2                	ld	s3,8(sp)
    8000277c:	6a02                	ld	s4,0(sp)
    8000277e:	6145                	addi	sp,sp,48
    80002780:	8082                	ret
    memmove(dst, (char *)src, len);
    80002782:	000a061b          	sext.w	a2,s4
    80002786:	85ce                	mv	a1,s3
    80002788:	854a                	mv	a0,s2
    8000278a:	ffffe097          	auipc	ra,0xffffe
    8000278e:	606080e7          	jalr	1542(ra) # 80000d90 <memmove>
    return 0;
    80002792:	8526                	mv	a0,s1
    80002794:	bff9                	j	80002772 <either_copyin+0x32>

0000000080002796 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002796:	715d                	addi	sp,sp,-80
    80002798:	e486                	sd	ra,72(sp)
    8000279a:	e0a2                	sd	s0,64(sp)
    8000279c:	fc26                	sd	s1,56(sp)
    8000279e:	f84a                	sd	s2,48(sp)
    800027a0:	f44e                	sd	s3,40(sp)
    800027a2:	f052                	sd	s4,32(sp)
    800027a4:	ec56                	sd	s5,24(sp)
    800027a6:	e85a                	sd	s6,16(sp)
    800027a8:	e45e                	sd	s7,8(sp)
    800027aa:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800027ac:	00006517          	auipc	a0,0x6
    800027b0:	86450513          	addi	a0,a0,-1948 # 80008010 <etext+0x10>
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	df6080e7          	jalr	-522(ra) # 800005aa <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800027bc:	00011497          	auipc	s1,0x11
    800027c0:	3ec48493          	addi	s1,s1,1004 # 80013ba8 <proc+0x158>
    800027c4:	0001a917          	auipc	s2,0x1a
    800027c8:	be490913          	addi	s2,s2,-1052 # 8001c3a8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027cc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800027ce:	00006997          	auipc	s3,0x6
    800027d2:	aaa98993          	addi	s3,s3,-1366 # 80008278 <etext+0x278>
    printf("%d %s %s %d %d", p->pid, state, p->name, p->tickets, p->arrival_time);
    800027d6:	00006a97          	auipc	s5,0x6
    800027da:	aaaa8a93          	addi	s5,s5,-1366 # 80008280 <etext+0x280>
    printf("\n");
    800027de:	00006a17          	auipc	s4,0x6
    800027e2:	832a0a13          	addi	s4,s4,-1998 # 80008010 <etext+0x10>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027e6:	00006b97          	auipc	s7,0x6
    800027ea:	f72b8b93          	addi	s7,s7,-142 # 80008758 <states.0>
    800027ee:	a02d                	j	80002818 <procdump+0x82>
    printf("%d %s %s %d %d", p->pid, state, p->name, p->tickets, p->arrival_time);
    800027f0:	0b86a783          	lw	a5,184(a3)
    800027f4:	0b46a703          	lw	a4,180(a3)
    800027f8:	ed86a583          	lw	a1,-296(a3)
    800027fc:	8556                	mv	a0,s5
    800027fe:	ffffe097          	auipc	ra,0xffffe
    80002802:	dac080e7          	jalr	-596(ra) # 800005aa <printf>
    printf("\n");
    80002806:	8552                	mv	a0,s4
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	da2080e7          	jalr	-606(ra) # 800005aa <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002810:	22048493          	addi	s1,s1,544
    80002814:	03248263          	beq	s1,s2,80002838 <procdump+0xa2>
    if (p->state == UNUSED)
    80002818:	86a6                	mv	a3,s1
    8000281a:	ec04a783          	lw	a5,-320(s1)
    8000281e:	dbed                	beqz	a5,80002810 <procdump+0x7a>
      state = "???";
    80002820:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002822:	fcfb67e3          	bltu	s6,a5,800027f0 <procdump+0x5a>
    80002826:	02079713          	slli	a4,a5,0x20
    8000282a:	01d75793          	srli	a5,a4,0x1d
    8000282e:	97de                	add	a5,a5,s7
    80002830:	6390                	ld	a2,0(a5)
    80002832:	fe5d                	bnez	a2,800027f0 <procdump+0x5a>
      state = "???";
    80002834:	864e                	mv	a2,s3
    80002836:	bf6d                	j	800027f0 <procdump+0x5a>
  }
}
    80002838:	60a6                	ld	ra,72(sp)
    8000283a:	6406                	ld	s0,64(sp)
    8000283c:	74e2                	ld	s1,56(sp)
    8000283e:	7942                	ld	s2,48(sp)
    80002840:	79a2                	ld	s3,40(sp)
    80002842:	7a02                	ld	s4,32(sp)
    80002844:	6ae2                	ld	s5,24(sp)
    80002846:	6b42                	ld	s6,16(sp)
    80002848:	6ba2                	ld	s7,8(sp)
    8000284a:	6161                	addi	sp,sp,80
    8000284c:	8082                	ret

000000008000284e <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    8000284e:	711d                	addi	sp,sp,-96
    80002850:	ec86                	sd	ra,88(sp)
    80002852:	e8a2                	sd	s0,80(sp)
    80002854:	e4a6                	sd	s1,72(sp)
    80002856:	e0ca                	sd	s2,64(sp)
    80002858:	fc4e                	sd	s3,56(sp)
    8000285a:	f852                	sd	s4,48(sp)
    8000285c:	f456                	sd	s5,40(sp)
    8000285e:	f05a                	sd	s6,32(sp)
    80002860:	ec5e                	sd	s7,24(sp)
    80002862:	e862                	sd	s8,16(sp)
    80002864:	e466                	sd	s9,8(sp)
    80002866:	e06a                	sd	s10,0(sp)
    80002868:	1080                	addi	s0,sp,96
    8000286a:	8b2a                	mv	s6,a0
    8000286c:	8bae                	mv	s7,a1
    8000286e:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002870:	fffff097          	auipc	ra,0xfffff
    80002874:	1da080e7          	jalr	474(ra) # 80001a4a <myproc>
    80002878:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000287a:	00011517          	auipc	a0,0x11
    8000287e:	dbe50513          	addi	a0,a0,-578 # 80013638 <wait_lock>
    80002882:	ffffe097          	auipc	ra,0xffffe
    80002886:	3b6080e7          	jalr	950(ra) # 80000c38 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000288a:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000288c:	4a15                	li	s4,5
        havekids = 1;
    8000288e:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002890:	0001a997          	auipc	s3,0x1a
    80002894:	9c098993          	addi	s3,s3,-1600 # 8001c250 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002898:	00011d17          	auipc	s10,0x11
    8000289c:	da0d0d13          	addi	s10,s10,-608 # 80013638 <wait_lock>
    800028a0:	a8e9                	j	8000297a <waitx+0x12c>
          pid = np->pid;
    800028a2:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800028a6:	1684a783          	lw	a5,360(s1)
    800028aa:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800028ae:	16c4a703          	lw	a4,364(s1)
    800028b2:	9f3d                	addw	a4,a4,a5
    800028b4:	1704a783          	lw	a5,368(s1)
    800028b8:	9f99                	subw	a5,a5,a4
    800028ba:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800028be:	000b0e63          	beqz	s6,800028da <waitx+0x8c>
    800028c2:	4691                	li	a3,4
    800028c4:	02c48613          	addi	a2,s1,44
    800028c8:	85da                	mv	a1,s6
    800028ca:	05093503          	ld	a0,80(s2)
    800028ce:	fffff097          	auipc	ra,0xfffff
    800028d2:	e14080e7          	jalr	-492(ra) # 800016e2 <copyout>
    800028d6:	04054363          	bltz	a0,8000291c <waitx+0xce>
          freeproc(np);
    800028da:	8526                	mv	a0,s1
    800028dc:	fffff097          	auipc	ra,0xfffff
    800028e0:	320080e7          	jalr	800(ra) # 80001bfc <freeproc>
          release(&np->lock);
    800028e4:	8526                	mv	a0,s1
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	406080e7          	jalr	1030(ra) # 80000cec <release>
          release(&wait_lock);
    800028ee:	00011517          	auipc	a0,0x11
    800028f2:	d4a50513          	addi	a0,a0,-694 # 80013638 <wait_lock>
    800028f6:	ffffe097          	auipc	ra,0xffffe
    800028fa:	3f6080e7          	jalr	1014(ra) # 80000cec <release>
  }
}
    800028fe:	854e                	mv	a0,s3
    80002900:	60e6                	ld	ra,88(sp)
    80002902:	6446                	ld	s0,80(sp)
    80002904:	64a6                	ld	s1,72(sp)
    80002906:	6906                	ld	s2,64(sp)
    80002908:	79e2                	ld	s3,56(sp)
    8000290a:	7a42                	ld	s4,48(sp)
    8000290c:	7aa2                	ld	s5,40(sp)
    8000290e:	7b02                	ld	s6,32(sp)
    80002910:	6be2                	ld	s7,24(sp)
    80002912:	6c42                	ld	s8,16(sp)
    80002914:	6ca2                	ld	s9,8(sp)
    80002916:	6d02                	ld	s10,0(sp)
    80002918:	6125                	addi	sp,sp,96
    8000291a:	8082                	ret
            release(&np->lock);
    8000291c:	8526                	mv	a0,s1
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	3ce080e7          	jalr	974(ra) # 80000cec <release>
            release(&wait_lock);
    80002926:	00011517          	auipc	a0,0x11
    8000292a:	d1250513          	addi	a0,a0,-750 # 80013638 <wait_lock>
    8000292e:	ffffe097          	auipc	ra,0xffffe
    80002932:	3be080e7          	jalr	958(ra) # 80000cec <release>
            return -1;
    80002936:	59fd                	li	s3,-1
    80002938:	b7d9                	j	800028fe <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    8000293a:	22048493          	addi	s1,s1,544
    8000293e:	03348463          	beq	s1,s3,80002966 <waitx+0x118>
      if (np->parent == p)
    80002942:	7c9c                	ld	a5,56(s1)
    80002944:	ff279be3          	bne	a5,s2,8000293a <waitx+0xec>
        acquire(&np->lock);
    80002948:	8526                	mv	a0,s1
    8000294a:	ffffe097          	auipc	ra,0xffffe
    8000294e:	2ee080e7          	jalr	750(ra) # 80000c38 <acquire>
        if (np->state == ZOMBIE)
    80002952:	4c9c                	lw	a5,24(s1)
    80002954:	f54787e3          	beq	a5,s4,800028a2 <waitx+0x54>
        release(&np->lock);
    80002958:	8526                	mv	a0,s1
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	392080e7          	jalr	914(ra) # 80000cec <release>
        havekids = 1;
    80002962:	8756                	mv	a4,s5
    80002964:	bfd9                	j	8000293a <waitx+0xec>
    if (!havekids || p->killed)
    80002966:	c305                	beqz	a4,80002986 <waitx+0x138>
    80002968:	02892783          	lw	a5,40(s2)
    8000296c:	ef89                	bnez	a5,80002986 <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000296e:	85ea                	mv	a1,s10
    80002970:	854a                	mv	a0,s2
    80002972:	00000097          	auipc	ra,0x0
    80002976:	93c080e7          	jalr	-1732(ra) # 800022ae <sleep>
    havekids = 0;
    8000297a:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000297c:	00011497          	auipc	s1,0x11
    80002980:	0d448493          	addi	s1,s1,212 # 80013a50 <proc>
    80002984:	bf7d                	j	80002942 <waitx+0xf4>
      release(&wait_lock);
    80002986:	00011517          	auipc	a0,0x11
    8000298a:	cb250513          	addi	a0,a0,-846 # 80013638 <wait_lock>
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	35e080e7          	jalr	862(ra) # 80000cec <release>
      return -1;
    80002996:	59fd                	li	s3,-1
    80002998:	b79d                	j	800028fe <waitx+0xb0>

000000008000299a <update_time>:

void update_time()
{
    8000299a:	7179                	addi	sp,sp,-48
    8000299c:	f406                	sd	ra,40(sp)
    8000299e:	f022                	sd	s0,32(sp)
    800029a0:	ec26                	sd	s1,24(sp)
    800029a2:	e84a                	sd	s2,16(sp)
    800029a4:	e44e                	sd	s3,8(sp)
    800029a6:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    800029a8:	00011497          	auipc	s1,0x11
    800029ac:	0a848493          	addi	s1,s1,168 # 80013a50 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    800029b0:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    800029b2:	0001a917          	auipc	s2,0x1a
    800029b6:	89e90913          	addi	s2,s2,-1890 # 8001c250 <tickslock>
    800029ba:	a811                	j	800029ce <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    800029bc:	8526                	mv	a0,s1
    800029be:	ffffe097          	auipc	ra,0xffffe
    800029c2:	32e080e7          	jalr	814(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800029c6:	22048493          	addi	s1,s1,544
    800029ca:	03248063          	beq	s1,s2,800029ea <update_time+0x50>
    acquire(&p->lock);
    800029ce:	8526                	mv	a0,s1
    800029d0:	ffffe097          	auipc	ra,0xffffe
    800029d4:	268080e7          	jalr	616(ra) # 80000c38 <acquire>
    if (p->state == RUNNING)
    800029d8:	4c9c                	lw	a5,24(s1)
    800029da:	ff3791e3          	bne	a5,s3,800029bc <update_time+0x22>
      p->rtime++;
    800029de:	1684a783          	lw	a5,360(s1)
    800029e2:	2785                	addiw	a5,a5,1
    800029e4:	16f4a423          	sw	a5,360(s1)
    800029e8:	bfd1                	j	800029bc <update_time+0x22>
  }
}
    800029ea:	70a2                	ld	ra,40(sp)
    800029ec:	7402                	ld	s0,32(sp)
    800029ee:	64e2                	ld	s1,24(sp)
    800029f0:	6942                	ld	s2,16(sp)
    800029f2:	69a2                	ld	s3,8(sp)
    800029f4:	6145                	addi	sp,sp,48
    800029f6:	8082                	ret

00000000800029f8 <count_syscalls>:

// Helper function to count syscalls for a process and its children
int
count_syscalls(struct proc *p, int syscall_num) {
    800029f8:	1141                	addi	sp,sp,-16
    800029fa:	e422                	sd	s0,8(sp)
    800029fc:	0800                	addi	s0,sp,16
  int count = 0;
  // Count the syscalls made by this process
  count += p->syscall_count[syscall_num];
    800029fe:	05c58593          	addi	a1,a1,92
    80002a02:	058a                	slli	a1,a1,0x2
    80002a04:	952e                	add	a0,a0,a1
        }
      }
    }
  }*/
  return count;
}
    80002a06:	4148                	lw	a0,4(a0)
    80002a08:	6422                	ld	s0,8(sp)
    80002a0a:	0141                	addi	sp,sp,16
    80002a0c:	8082                	ret

0000000080002a0e <getSysCount>:

int
getSysCount(int mask) {
    80002a0e:	1101                	addi	sp,sp,-32
    80002a10:	ec06                	sd	ra,24(sp)
    80002a12:	e822                	sd	s0,16(sp)
    80002a14:	e426                	sd	s1,8(sp)
    80002a16:	1000                	addi	s0,sp,32
    int syscall_num = -1;
    for (int i = 0; i < 31; i++) {
        if (mask == (1 << i)) {  // Check which bit in the mask is set
    80002a18:	4785                	li	a5,1
    80002a1a:	04f50063          	beq	a0,a5,80002a5a <getSysCount+0x4c>
    for (int i = 0; i < 31; i++) {
    80002a1e:	4481                	li	s1,0
    80002a20:	477d                	li	a4,31
        if (mask == (1 << i)) {  // Check which bit in the mask is set
    80002a22:	4685                	li	a3,1
    for (int i = 0; i < 31; i++) {
    80002a24:	2485                	addiw	s1,s1,1
    80002a26:	02e48863          	beq	s1,a4,80002a56 <getSysCount+0x48>
        if (mask == (1 << i)) {  // Check which bit in the mask is set
    80002a2a:	009697bb          	sllw	a5,a3,s1
    80002a2e:	fea79be3          	bne	a5,a0,80002a24 <getSysCount+0x16>
            syscall_num = i;
            break;
        }
    }
    if (syscall_num == -1)  // Invalid mask, no bits set
    80002a32:	57fd                	li	a5,-1
    80002a34:	00f48b63          	beq	s1,a5,80002a4a <getSysCount+0x3c>
        return -1;
    // Now we need to count syscalls for this process and its children
    struct proc *p = myproc();  // Get the current process
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	012080e7          	jalr	18(ra) # 80001a4a <myproc>
  count += p->syscall_count[syscall_num];
    80002a40:	05c48493          	addi	s1,s1,92
    80002a44:	048a                	slli	s1,s1,0x2
    80002a46:	9526                	add	a0,a0,s1
    80002a48:	4144                	lw	s1,4(a0)
    int total_count = 0;
    total_count += count_syscalls(p, syscall_num);  // Count for this process
    return total_count;
    80002a4a:	8526                	mv	a0,s1
    80002a4c:	60e2                	ld	ra,24(sp)
    80002a4e:	6442                	ld	s0,16(sp)
    80002a50:	64a2                	ld	s1,8(sp)
    80002a52:	6105                	addi	sp,sp,32
    80002a54:	8082                	ret
        return -1;
    80002a56:	54fd                	li	s1,-1
    80002a58:	bfcd                	j	80002a4a <getSysCount+0x3c>
            syscall_num = i;
    80002a5a:	4481                	li	s1,0
    80002a5c:	bff1                	j	80002a38 <getSysCount+0x2a>

0000000080002a5e <swtch>:
    80002a5e:	00153023          	sd	ra,0(a0)
    80002a62:	00253423          	sd	sp,8(a0)
    80002a66:	e900                	sd	s0,16(a0)
    80002a68:	ed04                	sd	s1,24(a0)
    80002a6a:	03253023          	sd	s2,32(a0)
    80002a6e:	03353423          	sd	s3,40(a0)
    80002a72:	03453823          	sd	s4,48(a0)
    80002a76:	03553c23          	sd	s5,56(a0)
    80002a7a:	05653023          	sd	s6,64(a0)
    80002a7e:	05753423          	sd	s7,72(a0)
    80002a82:	05853823          	sd	s8,80(a0)
    80002a86:	05953c23          	sd	s9,88(a0)
    80002a8a:	07a53023          	sd	s10,96(a0)
    80002a8e:	07b53423          	sd	s11,104(a0)
    80002a92:	0005b083          	ld	ra,0(a1)
    80002a96:	0085b103          	ld	sp,8(a1)
    80002a9a:	6980                	ld	s0,16(a1)
    80002a9c:	6d84                	ld	s1,24(a1)
    80002a9e:	0205b903          	ld	s2,32(a1)
    80002aa2:	0285b983          	ld	s3,40(a1)
    80002aa6:	0305ba03          	ld	s4,48(a1)
    80002aaa:	0385ba83          	ld	s5,56(a1)
    80002aae:	0405bb03          	ld	s6,64(a1)
    80002ab2:	0485bb83          	ld	s7,72(a1)
    80002ab6:	0505bc03          	ld	s8,80(a1)
    80002aba:	0585bc83          	ld	s9,88(a1)
    80002abe:	0605bd03          	ld	s10,96(a1)
    80002ac2:	0685bd83          	ld	s11,104(a1)
    80002ac6:	8082                	ret

0000000080002ac8 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002ac8:	1141                	addi	sp,sp,-16
    80002aca:	e406                	sd	ra,8(sp)
    80002acc:	e022                	sd	s0,0(sp)
    80002ace:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002ad0:	00005597          	auipc	a1,0x5
    80002ad4:	7f058593          	addi	a1,a1,2032 # 800082c0 <etext+0x2c0>
    80002ad8:	00019517          	auipc	a0,0x19
    80002adc:	77850513          	addi	a0,a0,1912 # 8001c250 <tickslock>
    80002ae0:	ffffe097          	auipc	ra,0xffffe
    80002ae4:	0c8080e7          	jalr	200(ra) # 80000ba8 <initlock>
}
    80002ae8:	60a2                	ld	ra,8(sp)
    80002aea:	6402                	ld	s0,0(sp)
    80002aec:	0141                	addi	sp,sp,16
    80002aee:	8082                	ret

0000000080002af0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002af0:	1141                	addi	sp,sp,-16
    80002af2:	e422                	sd	s0,8(sp)
    80002af4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002af6:	00003797          	auipc	a5,0x3
    80002afa:	7aa78793          	addi	a5,a5,1962 # 800062a0 <kernelvec>
    80002afe:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b02:	6422                	ld	s0,8(sp)
    80002b04:	0141                	addi	sp,sp,16
    80002b06:	8082                	ret

0000000080002b08 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002b08:	1141                	addi	sp,sp,-16
    80002b0a:	e406                	sd	ra,8(sp)
    80002b0c:	e022                	sd	s0,0(sp)
    80002b0e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b10:	fffff097          	auipc	ra,0xfffff
    80002b14:	f3a080e7          	jalr	-198(ra) # 80001a4a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b18:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b1c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b1e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002b22:	00004697          	auipc	a3,0x4
    80002b26:	4de68693          	addi	a3,a3,1246 # 80007000 <_trampoline>
    80002b2a:	00004717          	auipc	a4,0x4
    80002b2e:	4d670713          	addi	a4,a4,1238 # 80007000 <_trampoline>
    80002b32:	8f15                	sub	a4,a4,a3
    80002b34:	040007b7          	lui	a5,0x4000
    80002b38:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002b3a:	07b2                	slli	a5,a5,0xc
    80002b3c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b3e:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b42:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b44:	18002673          	csrr	a2,satp
    80002b48:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b4a:	6d30                	ld	a2,88(a0)
    80002b4c:	6138                	ld	a4,64(a0)
    80002b4e:	6585                	lui	a1,0x1
    80002b50:	972e                	add	a4,a4,a1
    80002b52:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b54:	6d38                	ld	a4,88(a0)
    80002b56:	00000617          	auipc	a2,0x0
    80002b5a:	14660613          	addi	a2,a2,326 # 80002c9c <usertrap>
    80002b5e:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002b60:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b62:	8612                	mv	a2,tp
    80002b64:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b66:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b6a:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b6e:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b72:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b76:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b78:	6f18                	ld	a4,24(a4)
    80002b7a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b7e:	6928                	ld	a0,80(a0)
    80002b80:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b82:	00004717          	auipc	a4,0x4
    80002b86:	51a70713          	addi	a4,a4,1306 # 8000709c <userret>
    80002b8a:	8f15                	sub	a4,a4,a3
    80002b8c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002b8e:	577d                	li	a4,-1
    80002b90:	177e                	slli	a4,a4,0x3f
    80002b92:	8d59                	or	a0,a0,a4
    80002b94:	9782                	jalr	a5
}
    80002b96:	60a2                	ld	ra,8(sp)
    80002b98:	6402                	ld	s0,0(sp)
    80002b9a:	0141                	addi	sp,sp,16
    80002b9c:	8082                	ret

0000000080002b9e <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002b9e:	1101                	addi	sp,sp,-32
    80002ba0:	ec06                	sd	ra,24(sp)
    80002ba2:	e822                	sd	s0,16(sp)
    80002ba4:	e426                	sd	s1,8(sp)
    80002ba6:	e04a                	sd	s2,0(sp)
    80002ba8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002baa:	00019917          	auipc	s2,0x19
    80002bae:	6a690913          	addi	s2,s2,1702 # 8001c250 <tickslock>
    80002bb2:	854a                	mv	a0,s2
    80002bb4:	ffffe097          	auipc	ra,0xffffe
    80002bb8:	084080e7          	jalr	132(ra) # 80000c38 <acquire>
  ticks++;
    80002bbc:	00008497          	auipc	s1,0x8
    80002bc0:	7f448493          	addi	s1,s1,2036 # 8000b3b0 <ticks>
    80002bc4:	409c                	lw	a5,0(s1)
    80002bc6:	2785                	addiw	a5,a5,1
    80002bc8:	c09c                	sw	a5,0(s1)
  update_time();
    80002bca:	00000097          	auipc	ra,0x0
    80002bce:	dd0080e7          	jalr	-560(ra) # 8000299a <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002bd2:	8526                	mv	a0,s1
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	73e080e7          	jalr	1854(ra) # 80002312 <wakeup>
  release(&tickslock);
    80002bdc:	854a                	mv	a0,s2
    80002bde:	ffffe097          	auipc	ra,0xffffe
    80002be2:	10e080e7          	jalr	270(ra) # 80000cec <release>
}
    80002be6:	60e2                	ld	ra,24(sp)
    80002be8:	6442                	ld	s0,16(sp)
    80002bea:	64a2                	ld	s1,8(sp)
    80002bec:	6902                	ld	s2,0(sp)
    80002bee:	6105                	addi	sp,sp,32
    80002bf0:	8082                	ret

0000000080002bf2 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bf2:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    80002bf6:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    80002bf8:	0a07d163          	bgez	a5,80002c9a <devintr+0xa8>
{
    80002bfc:	1101                	addi	sp,sp,-32
    80002bfe:	ec06                	sd	ra,24(sp)
    80002c00:	e822                	sd	s0,16(sp)
    80002c02:	1000                	addi	s0,sp,32
      (scause & 0xff) == 9)
    80002c04:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    80002c08:	46a5                	li	a3,9
    80002c0a:	00d70c63          	beq	a4,a3,80002c22 <devintr+0x30>
  else if (scause == 0x8000000000000001L)
    80002c0e:	577d                	li	a4,-1
    80002c10:	177e                	slli	a4,a4,0x3f
    80002c12:	0705                	addi	a4,a4,1
    return 0;
    80002c14:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002c16:	06e78163          	beq	a5,a4,80002c78 <devintr+0x86>
  }
}
    80002c1a:	60e2                	ld	ra,24(sp)
    80002c1c:	6442                	ld	s0,16(sp)
    80002c1e:	6105                	addi	sp,sp,32
    80002c20:	8082                	ret
    80002c22:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    80002c24:	00003097          	auipc	ra,0x3
    80002c28:	788080e7          	jalr	1928(ra) # 800063ac <plic_claim>
    80002c2c:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002c2e:	47a9                	li	a5,10
    80002c30:	00f50963          	beq	a0,a5,80002c42 <devintr+0x50>
    else if (irq == VIRTIO0_IRQ)
    80002c34:	4785                	li	a5,1
    80002c36:	00f50b63          	beq	a0,a5,80002c4c <devintr+0x5a>
    return 1;
    80002c3a:	4505                	li	a0,1
    else if (irq)
    80002c3c:	ec89                	bnez	s1,80002c56 <devintr+0x64>
    80002c3e:	64a2                	ld	s1,8(sp)
    80002c40:	bfe9                	j	80002c1a <devintr+0x28>
      uartintr();
    80002c42:	ffffe097          	auipc	ra,0xffffe
    80002c46:	db8080e7          	jalr	-584(ra) # 800009fa <uartintr>
    if (irq)
    80002c4a:	a839                	j	80002c68 <devintr+0x76>
      virtio_disk_intr();
    80002c4c:	00004097          	auipc	ra,0x4
    80002c50:	c8a080e7          	jalr	-886(ra) # 800068d6 <virtio_disk_intr>
    if (irq)
    80002c54:	a811                	j	80002c68 <devintr+0x76>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c56:	85a6                	mv	a1,s1
    80002c58:	00005517          	auipc	a0,0x5
    80002c5c:	67050513          	addi	a0,a0,1648 # 800082c8 <etext+0x2c8>
    80002c60:	ffffe097          	auipc	ra,0xffffe
    80002c64:	94a080e7          	jalr	-1718(ra) # 800005aa <printf>
      plic_complete(irq);
    80002c68:	8526                	mv	a0,s1
    80002c6a:	00003097          	auipc	ra,0x3
    80002c6e:	766080e7          	jalr	1894(ra) # 800063d0 <plic_complete>
    return 1;
    80002c72:	4505                	li	a0,1
    80002c74:	64a2                	ld	s1,8(sp)
    80002c76:	b755                	j	80002c1a <devintr+0x28>
    if (cpuid() == 0)
    80002c78:	fffff097          	auipc	ra,0xfffff
    80002c7c:	da6080e7          	jalr	-602(ra) # 80001a1e <cpuid>
    80002c80:	c901                	beqz	a0,80002c90 <devintr+0x9e>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c82:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c86:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c88:	14479073          	csrw	sip,a5
    return 2;
    80002c8c:	4509                	li	a0,2
    80002c8e:	b771                	j	80002c1a <devintr+0x28>
      clockintr();
    80002c90:	00000097          	auipc	ra,0x0
    80002c94:	f0e080e7          	jalr	-242(ra) # 80002b9e <clockintr>
    80002c98:	b7ed                	j	80002c82 <devintr+0x90>
}
    80002c9a:	8082                	ret

0000000080002c9c <usertrap>:
{
    80002c9c:	1101                	addi	sp,sp,-32
    80002c9e:	ec06                	sd	ra,24(sp)
    80002ca0:	e822                	sd	s0,16(sp)
    80002ca2:	e426                	sd	s1,8(sp)
    80002ca4:	e04a                	sd	s2,0(sp)
    80002ca6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ca8:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002cac:	1007f793          	andi	a5,a5,256
    80002cb0:	e3b1                	bnez	a5,80002cf4 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cb2:	00003797          	auipc	a5,0x3
    80002cb6:	5ee78793          	addi	a5,a5,1518 # 800062a0 <kernelvec>
    80002cba:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002cbe:	fffff097          	auipc	ra,0xfffff
    80002cc2:	d8c080e7          	jalr	-628(ra) # 80001a4a <myproc>
    80002cc6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002cc8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cca:	14102773          	csrr	a4,sepc
    80002cce:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cd0:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002cd4:	47a1                	li	a5,8
    80002cd6:	02f70763          	beq	a4,a5,80002d04 <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    80002cda:	00000097          	auipc	ra,0x0
    80002cde:	f18080e7          	jalr	-232(ra) # 80002bf2 <devintr>
    80002ce2:	892a                	mv	s2,a0
    80002ce4:	c92d                	beqz	a0,80002d56 <usertrap+0xba>
  if (killed(p))
    80002ce6:	8526                	mv	a0,s1
    80002ce8:	00000097          	auipc	ra,0x0
    80002cec:	886080e7          	jalr	-1914(ra) # 8000256e <killed>
    80002cf0:	c555                	beqz	a0,80002d9c <usertrap+0x100>
    80002cf2:	a045                	j	80002d92 <usertrap+0xf6>
    panic("usertrap: not from user mode");
    80002cf4:	00005517          	auipc	a0,0x5
    80002cf8:	5f450513          	addi	a0,a0,1524 # 800082e8 <etext+0x2e8>
    80002cfc:	ffffe097          	auipc	ra,0xffffe
    80002d00:	864080e7          	jalr	-1948(ra) # 80000560 <panic>
    if (killed(p))
    80002d04:	00000097          	auipc	ra,0x0
    80002d08:	86a080e7          	jalr	-1942(ra) # 8000256e <killed>
    80002d0c:	ed1d                	bnez	a0,80002d4a <usertrap+0xae>
    p->trapframe->epc += 4;
    80002d0e:	6cb8                	ld	a4,88(s1)
    80002d10:	6f1c                	ld	a5,24(a4)
    80002d12:	0791                	addi	a5,a5,4
    80002d14:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d16:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d1a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d1e:	10079073          	csrw	sstatus,a5
    syscall();
    80002d22:	00000097          	auipc	ra,0x0
    80002d26:	330080e7          	jalr	816(ra) # 80003052 <syscall>
  if (killed(p))
    80002d2a:	8526                	mv	a0,s1
    80002d2c:	00000097          	auipc	ra,0x0
    80002d30:	842080e7          	jalr	-1982(ra) # 8000256e <killed>
    80002d34:	ed31                	bnez	a0,80002d90 <usertrap+0xf4>
  usertrapret();
    80002d36:	00000097          	auipc	ra,0x0
    80002d3a:	dd2080e7          	jalr	-558(ra) # 80002b08 <usertrapret>
}
    80002d3e:	60e2                	ld	ra,24(sp)
    80002d40:	6442                	ld	s0,16(sp)
    80002d42:	64a2                	ld	s1,8(sp)
    80002d44:	6902                	ld	s2,0(sp)
    80002d46:	6105                	addi	sp,sp,32
    80002d48:	8082                	ret
      exit(-1);
    80002d4a:	557d                	li	a0,-1
    80002d4c:	fffff097          	auipc	ra,0xfffff
    80002d50:	696080e7          	jalr	1686(ra) # 800023e2 <exit>
    80002d54:	bf6d                	j	80002d0e <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d56:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d5a:	5890                	lw	a2,48(s1)
    80002d5c:	00005517          	auipc	a0,0x5
    80002d60:	5ac50513          	addi	a0,a0,1452 # 80008308 <etext+0x308>
    80002d64:	ffffe097          	auipc	ra,0xffffe
    80002d68:	846080e7          	jalr	-1978(ra) # 800005aa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d6c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d70:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d74:	00005517          	auipc	a0,0x5
    80002d78:	5c450513          	addi	a0,a0,1476 # 80008338 <etext+0x338>
    80002d7c:	ffffe097          	auipc	ra,0xffffe
    80002d80:	82e080e7          	jalr	-2002(ra) # 800005aa <printf>
    setkilled(p);
    80002d84:	8526                	mv	a0,s1
    80002d86:	fffff097          	auipc	ra,0xfffff
    80002d8a:	7bc080e7          	jalr	1980(ra) # 80002542 <setkilled>
    80002d8e:	bf71                	j	80002d2a <usertrap+0x8e>
  if (killed(p))
    80002d90:	4901                	li	s2,0
    exit(-1);
    80002d92:	557d                	li	a0,-1
    80002d94:	fffff097          	auipc	ra,0xfffff
    80002d98:	64e080e7          	jalr	1614(ra) # 800023e2 <exit>
  if (which_dev == 2) {  // Timer interrupt
    80002d9c:	4789                	li	a5,2
    80002d9e:	f8f91ce3          	bne	s2,a5,80002d36 <usertrap+0x9a>
    p->ticks_in_level++;
    80002da2:	21c4a783          	lw	a5,540(s1)
    80002da6:	2785                	addiw	a5,a5,1
    80002da8:	20f4ae23          	sw	a5,540(s1)
    if (p->state == RUNNING)
    80002dac:	4c98                	lw	a4,24(s1)
    80002dae:	4791                	li	a5,4
    80002db0:	f8f713e3          	bne	a4,a5,80002d36 <usertrap+0x9a>
      yield();
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	4ba080e7          	jalr	1210(ra) # 8000226e <yield>
    if (p && p->state == RUNNING) {
    80002dbc:	4c98                	lw	a4,24(s1)
    80002dbe:	4791                	li	a5,4
    80002dc0:	f6f71be3          	bne	a4,a5,80002d36 <usertrap+0x9a>
        p->ticks_left--;
    80002dc4:	1f44a783          	lw	a5,500(s1)
    80002dc8:	37fd                	addiw	a5,a5,-1
    80002dca:	0007871b          	sext.w	a4,a5
    80002dce:	1ef4aa23          	sw	a5,500(s1)
        if (p->ticks_left == 0 && p->alarmticks > 0 && !p->in_alarm) {
    80002dd2:	f335                	bnez	a4,80002d36 <usertrap+0x9a>
    80002dd4:	1f04a783          	lw	a5,496(s1)
    80002dd8:	f4f05fe3          	blez	a5,80002d36 <usertrap+0x9a>
    80002ddc:	2084a703          	lw	a4,520(s1)
    80002de0:	fb39                	bnez	a4,80002d36 <usertrap+0x9a>
            p->in_alarm = 1;  // Mark that we're in the alarm handler
    80002de2:	4705                	li	a4,1
    80002de4:	20e4a423          	sw	a4,520(s1)
            p->ticks_left = p->alarmticks;  // Reset the tick counter
    80002de8:	1ef4aa23          	sw	a5,500(s1)
            memmove(p->original_trapframe, p->trapframe, sizeof(struct trapframe));
    80002dec:	12000613          	li	a2,288
    80002df0:	6cac                	ld	a1,88(s1)
    80002df2:	2004b503          	ld	a0,512(s1)
    80002df6:	ffffe097          	auipc	ra,0xffffe
    80002dfa:	f9a080e7          	jalr	-102(ra) # 80000d90 <memmove>
            p->trapframe->epc = (uint64)p->alarm_handler;
    80002dfe:	6cbc                	ld	a5,88(s1)
    80002e00:	1f84b703          	ld	a4,504(s1)
    80002e04:	ef98                	sd	a4,24(a5)
    80002e06:	bf05                	j	80002d36 <usertrap+0x9a>

0000000080002e08 <kerneltrap>:
{
    80002e08:	7179                	addi	sp,sp,-48
    80002e0a:	f406                	sd	ra,40(sp)
    80002e0c:	f022                	sd	s0,32(sp)
    80002e0e:	ec26                	sd	s1,24(sp)
    80002e10:	e84a                	sd	s2,16(sp)
    80002e12:	e44e                	sd	s3,8(sp)
    80002e14:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e16:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e1a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e1e:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002e22:	1004f793          	andi	a5,s1,256
    80002e26:	cb85                	beqz	a5,80002e56 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e28:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e2c:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002e2e:	ef85                	bnez	a5,80002e66 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002e30:	00000097          	auipc	ra,0x0
    80002e34:	dc2080e7          	jalr	-574(ra) # 80002bf2 <devintr>
    80002e38:	cd1d                	beqz	a0,80002e76 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e3a:	4789                	li	a5,2
    80002e3c:	06f50a63          	beq	a0,a5,80002eb0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e40:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e44:	10049073          	csrw	sstatus,s1
}
    80002e48:	70a2                	ld	ra,40(sp)
    80002e4a:	7402                	ld	s0,32(sp)
    80002e4c:	64e2                	ld	s1,24(sp)
    80002e4e:	6942                	ld	s2,16(sp)
    80002e50:	69a2                	ld	s3,8(sp)
    80002e52:	6145                	addi	sp,sp,48
    80002e54:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e56:	00005517          	auipc	a0,0x5
    80002e5a:	50250513          	addi	a0,a0,1282 # 80008358 <etext+0x358>
    80002e5e:	ffffd097          	auipc	ra,0xffffd
    80002e62:	702080e7          	jalr	1794(ra) # 80000560 <panic>
    panic("kerneltrap: interrupts enabled");
    80002e66:	00005517          	auipc	a0,0x5
    80002e6a:	51a50513          	addi	a0,a0,1306 # 80008380 <etext+0x380>
    80002e6e:	ffffd097          	auipc	ra,0xffffd
    80002e72:	6f2080e7          	jalr	1778(ra) # 80000560 <panic>
    printf("scause %p\n", scause);
    80002e76:	85ce                	mv	a1,s3
    80002e78:	00005517          	auipc	a0,0x5
    80002e7c:	52850513          	addi	a0,a0,1320 # 800083a0 <etext+0x3a0>
    80002e80:	ffffd097          	auipc	ra,0xffffd
    80002e84:	72a080e7          	jalr	1834(ra) # 800005aa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e88:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e8c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e90:	00005517          	auipc	a0,0x5
    80002e94:	52050513          	addi	a0,a0,1312 # 800083b0 <etext+0x3b0>
    80002e98:	ffffd097          	auipc	ra,0xffffd
    80002e9c:	712080e7          	jalr	1810(ra) # 800005aa <printf>
    panic("kerneltrap");
    80002ea0:	00005517          	auipc	a0,0x5
    80002ea4:	52850513          	addi	a0,a0,1320 # 800083c8 <etext+0x3c8>
    80002ea8:	ffffd097          	auipc	ra,0xffffd
    80002eac:	6b8080e7          	jalr	1720(ra) # 80000560 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002eb0:	fffff097          	auipc	ra,0xfffff
    80002eb4:	b9a080e7          	jalr	-1126(ra) # 80001a4a <myproc>
    80002eb8:	d541                	beqz	a0,80002e40 <kerneltrap+0x38>
    80002eba:	fffff097          	auipc	ra,0xfffff
    80002ebe:	b90080e7          	jalr	-1136(ra) # 80001a4a <myproc>
    80002ec2:	4d18                	lw	a4,24(a0)
    80002ec4:	4791                	li	a5,4
    80002ec6:	f6f71de3          	bne	a4,a5,80002e40 <kerneltrap+0x38>
    yield();
    80002eca:	fffff097          	auipc	ra,0xfffff
    80002ece:	3a4080e7          	jalr	932(ra) # 8000226e <yield>
    80002ed2:	b7bd                	j	80002e40 <kerneltrap+0x38>

0000000080002ed4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ed4:	1101                	addi	sp,sp,-32
    80002ed6:	ec06                	sd	ra,24(sp)
    80002ed8:	e822                	sd	s0,16(sp)
    80002eda:	e426                	sd	s1,8(sp)
    80002edc:	1000                	addi	s0,sp,32
    80002ede:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ee0:	fffff097          	auipc	ra,0xfffff
    80002ee4:	b6a080e7          	jalr	-1174(ra) # 80001a4a <myproc>
  switch (n) {
    80002ee8:	4795                	li	a5,5
    80002eea:	0497e163          	bltu	a5,s1,80002f2c <argraw+0x58>
    80002eee:	048a                	slli	s1,s1,0x2
    80002ef0:	00006717          	auipc	a4,0x6
    80002ef4:	89870713          	addi	a4,a4,-1896 # 80008788 <states.0+0x30>
    80002ef8:	94ba                	add	s1,s1,a4
    80002efa:	409c                	lw	a5,0(s1)
    80002efc:	97ba                	add	a5,a5,a4
    80002efe:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f00:	6d3c                	ld	a5,88(a0)
    80002f02:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f04:	60e2                	ld	ra,24(sp)
    80002f06:	6442                	ld	s0,16(sp)
    80002f08:	64a2                	ld	s1,8(sp)
    80002f0a:	6105                	addi	sp,sp,32
    80002f0c:	8082                	ret
    return p->trapframe->a1;
    80002f0e:	6d3c                	ld	a5,88(a0)
    80002f10:	7fa8                	ld	a0,120(a5)
    80002f12:	bfcd                	j	80002f04 <argraw+0x30>
    return p->trapframe->a2;
    80002f14:	6d3c                	ld	a5,88(a0)
    80002f16:	63c8                	ld	a0,128(a5)
    80002f18:	b7f5                	j	80002f04 <argraw+0x30>
    return p->trapframe->a3;
    80002f1a:	6d3c                	ld	a5,88(a0)
    80002f1c:	67c8                	ld	a0,136(a5)
    80002f1e:	b7dd                	j	80002f04 <argraw+0x30>
    return p->trapframe->a4;
    80002f20:	6d3c                	ld	a5,88(a0)
    80002f22:	6bc8                	ld	a0,144(a5)
    80002f24:	b7c5                	j	80002f04 <argraw+0x30>
    return p->trapframe->a5;
    80002f26:	6d3c                	ld	a5,88(a0)
    80002f28:	6fc8                	ld	a0,152(a5)
    80002f2a:	bfe9                	j	80002f04 <argraw+0x30>
  panic("argraw");
    80002f2c:	00005517          	auipc	a0,0x5
    80002f30:	4ac50513          	addi	a0,a0,1196 # 800083d8 <etext+0x3d8>
    80002f34:	ffffd097          	auipc	ra,0xffffd
    80002f38:	62c080e7          	jalr	1580(ra) # 80000560 <panic>

0000000080002f3c <fetchaddr>:
{
    80002f3c:	1101                	addi	sp,sp,-32
    80002f3e:	ec06                	sd	ra,24(sp)
    80002f40:	e822                	sd	s0,16(sp)
    80002f42:	e426                	sd	s1,8(sp)
    80002f44:	e04a                	sd	s2,0(sp)
    80002f46:	1000                	addi	s0,sp,32
    80002f48:	84aa                	mv	s1,a0
    80002f4a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f4c:	fffff097          	auipc	ra,0xfffff
    80002f50:	afe080e7          	jalr	-1282(ra) # 80001a4a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f54:	653c                	ld	a5,72(a0)
    80002f56:	02f4f863          	bgeu	s1,a5,80002f86 <fetchaddr+0x4a>
    80002f5a:	00848713          	addi	a4,s1,8
    80002f5e:	02e7e663          	bltu	a5,a4,80002f8a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f62:	46a1                	li	a3,8
    80002f64:	8626                	mv	a2,s1
    80002f66:	85ca                	mv	a1,s2
    80002f68:	6928                	ld	a0,80(a0)
    80002f6a:	fffff097          	auipc	ra,0xfffff
    80002f6e:	804080e7          	jalr	-2044(ra) # 8000176e <copyin>
    80002f72:	00a03533          	snez	a0,a0
    80002f76:	40a00533          	neg	a0,a0
}
    80002f7a:	60e2                	ld	ra,24(sp)
    80002f7c:	6442                	ld	s0,16(sp)
    80002f7e:	64a2                	ld	s1,8(sp)
    80002f80:	6902                	ld	s2,0(sp)
    80002f82:	6105                	addi	sp,sp,32
    80002f84:	8082                	ret
    return -1;
    80002f86:	557d                	li	a0,-1
    80002f88:	bfcd                	j	80002f7a <fetchaddr+0x3e>
    80002f8a:	557d                	li	a0,-1
    80002f8c:	b7fd                	j	80002f7a <fetchaddr+0x3e>

0000000080002f8e <fetchstr>:
{
    80002f8e:	7179                	addi	sp,sp,-48
    80002f90:	f406                	sd	ra,40(sp)
    80002f92:	f022                	sd	s0,32(sp)
    80002f94:	ec26                	sd	s1,24(sp)
    80002f96:	e84a                	sd	s2,16(sp)
    80002f98:	e44e                	sd	s3,8(sp)
    80002f9a:	1800                	addi	s0,sp,48
    80002f9c:	892a                	mv	s2,a0
    80002f9e:	84ae                	mv	s1,a1
    80002fa0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002fa2:	fffff097          	auipc	ra,0xfffff
    80002fa6:	aa8080e7          	jalr	-1368(ra) # 80001a4a <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002faa:	86ce                	mv	a3,s3
    80002fac:	864a                	mv	a2,s2
    80002fae:	85a6                	mv	a1,s1
    80002fb0:	6928                	ld	a0,80(a0)
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	84a080e7          	jalr	-1974(ra) # 800017fc <copyinstr>
    80002fba:	00054e63          	bltz	a0,80002fd6 <fetchstr+0x48>
  return strlen(buf);
    80002fbe:	8526                	mv	a0,s1
    80002fc0:	ffffe097          	auipc	ra,0xffffe
    80002fc4:	ee8080e7          	jalr	-280(ra) # 80000ea8 <strlen>
}
    80002fc8:	70a2                	ld	ra,40(sp)
    80002fca:	7402                	ld	s0,32(sp)
    80002fcc:	64e2                	ld	s1,24(sp)
    80002fce:	6942                	ld	s2,16(sp)
    80002fd0:	69a2                	ld	s3,8(sp)
    80002fd2:	6145                	addi	sp,sp,48
    80002fd4:	8082                	ret
    return -1;
    80002fd6:	557d                	li	a0,-1
    80002fd8:	bfc5                	j	80002fc8 <fetchstr+0x3a>

0000000080002fda <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002fda:	1101                	addi	sp,sp,-32
    80002fdc:	ec06                	sd	ra,24(sp)
    80002fde:	e822                	sd	s0,16(sp)
    80002fe0:	e426                	sd	s1,8(sp)
    80002fe2:	1000                	addi	s0,sp,32
    80002fe4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002fe6:	00000097          	auipc	ra,0x0
    80002fea:	eee080e7          	jalr	-274(ra) # 80002ed4 <argraw>
    80002fee:	c088                	sw	a0,0(s1)
}
    80002ff0:	60e2                	ld	ra,24(sp)
    80002ff2:	6442                	ld	s0,16(sp)
    80002ff4:	64a2                	ld	s1,8(sp)
    80002ff6:	6105                	addi	sp,sp,32
    80002ff8:	8082                	ret

0000000080002ffa <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002ffa:	1101                	addi	sp,sp,-32
    80002ffc:	ec06                	sd	ra,24(sp)
    80002ffe:	e822                	sd	s0,16(sp)
    80003000:	e426                	sd	s1,8(sp)
    80003002:	1000                	addi	s0,sp,32
    80003004:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003006:	00000097          	auipc	ra,0x0
    8000300a:	ece080e7          	jalr	-306(ra) # 80002ed4 <argraw>
    8000300e:	e088                	sd	a0,0(s1)
}
    80003010:	60e2                	ld	ra,24(sp)
    80003012:	6442                	ld	s0,16(sp)
    80003014:	64a2                	ld	s1,8(sp)
    80003016:	6105                	addi	sp,sp,32
    80003018:	8082                	ret

000000008000301a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000301a:	7179                	addi	sp,sp,-48
    8000301c:	f406                	sd	ra,40(sp)
    8000301e:	f022                	sd	s0,32(sp)
    80003020:	ec26                	sd	s1,24(sp)
    80003022:	e84a                	sd	s2,16(sp)
    80003024:	1800                	addi	s0,sp,48
    80003026:	84ae                	mv	s1,a1
    80003028:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    8000302a:	fd840593          	addi	a1,s0,-40
    8000302e:	00000097          	auipc	ra,0x0
    80003032:	fcc080e7          	jalr	-52(ra) # 80002ffa <argaddr>
  return fetchstr(addr, buf, max);
    80003036:	864a                	mv	a2,s2
    80003038:	85a6                	mv	a1,s1
    8000303a:	fd843503          	ld	a0,-40(s0)
    8000303e:	00000097          	auipc	ra,0x0
    80003042:	f50080e7          	jalr	-176(ra) # 80002f8e <fetchstr>
}
    80003046:	70a2                	ld	ra,40(sp)
    80003048:	7402                	ld	s0,32(sp)
    8000304a:	64e2                	ld	s1,24(sp)
    8000304c:	6942                	ld	s2,16(sp)
    8000304e:	6145                	addi	sp,sp,48
    80003050:	8082                	ret

0000000080003052 <syscall>:
[SYS_settickets] sys_settickets
};

void
syscall(void)
{
    80003052:	1101                	addi	sp,sp,-32
    80003054:	ec06                	sd	ra,24(sp)
    80003056:	e822                	sd	s0,16(sp)
    80003058:	e426                	sd	s1,8(sp)
    8000305a:	e04a                	sd	s2,0(sp)
    8000305c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000305e:	fffff097          	auipc	ra,0xfffff
    80003062:	9ec080e7          	jalr	-1556(ra) # 80001a4a <myproc>
    80003066:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003068:	05853903          	ld	s2,88(a0)
    8000306c:	0a893783          	ld	a5,168(s2)
    80003070:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003074:	37fd                	addiw	a5,a5,-1
    80003076:	4765                	li	a4,25
    80003078:	02f76763          	bltu	a4,a5,800030a6 <syscall+0x54>
    8000307c:	00369713          	slli	a4,a3,0x3
    80003080:	00005797          	auipc	a5,0x5
    80003084:	72078793          	addi	a5,a5,1824 # 800087a0 <syscalls>
    80003088:	97ba                	add	a5,a5,a4
    8000308a:	6398                	ld	a4,0(a5)
    8000308c:	cf09                	beqz	a4,800030a6 <syscall+0x54>
    // Use num to lookup the system call function for num, call it,
    p->syscall_count[num]++;
    8000308e:	068a                	slli	a3,a3,0x2
    80003090:	00d504b3          	add	s1,a0,a3
    80003094:	1744a783          	lw	a5,372(s1)
    80003098:	2785                	addiw	a5,a5,1
    8000309a:	16f4aa23          	sw	a5,372(s1)
    //printf("%d\n", p->syscall_count[num]);
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    8000309e:	9702                	jalr	a4
    800030a0:	06a93823          	sd	a0,112(s2)
    800030a4:	a839                	j	800030c2 <syscall+0x70>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800030a6:	15848613          	addi	a2,s1,344
    800030aa:	588c                	lw	a1,48(s1)
    800030ac:	00005517          	auipc	a0,0x5
    800030b0:	33450513          	addi	a0,a0,820 # 800083e0 <etext+0x3e0>
    800030b4:	ffffd097          	auipc	ra,0xffffd
    800030b8:	4f6080e7          	jalr	1270(ra) # 800005aa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800030bc:	6cbc                	ld	a5,88(s1)
    800030be:	577d                	li	a4,-1
    800030c0:	fbb8                	sd	a4,112(a5)
  }
    800030c2:	60e2                	ld	ra,24(sp)
    800030c4:	6442                	ld	s0,16(sp)
    800030c6:	64a2                	ld	s1,8(sp)
    800030c8:	6902                	ld	s2,0(sp)
    800030ca:	6105                	addi	sp,sp,32
    800030cc:	8082                	ret

00000000800030ce <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800030ce:	1101                	addi	sp,sp,-32
    800030d0:	ec06                	sd	ra,24(sp)
    800030d2:	e822                	sd	s0,16(sp)
    800030d4:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800030d6:	fec40593          	addi	a1,s0,-20
    800030da:	4501                	li	a0,0
    800030dc:	00000097          	auipc	ra,0x0
    800030e0:	efe080e7          	jalr	-258(ra) # 80002fda <argint>
  exit(n);
    800030e4:	fec42503          	lw	a0,-20(s0)
    800030e8:	fffff097          	auipc	ra,0xfffff
    800030ec:	2fa080e7          	jalr	762(ra) # 800023e2 <exit>
  return 0; // not reached
}
    800030f0:	4501                	li	a0,0
    800030f2:	60e2                	ld	ra,24(sp)
    800030f4:	6442                	ld	s0,16(sp)
    800030f6:	6105                	addi	sp,sp,32
    800030f8:	8082                	ret

00000000800030fa <sys_getpid>:

uint64
sys_getpid(void)
{
    800030fa:	1141                	addi	sp,sp,-16
    800030fc:	e406                	sd	ra,8(sp)
    800030fe:	e022                	sd	s0,0(sp)
    80003100:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003102:	fffff097          	auipc	ra,0xfffff
    80003106:	948080e7          	jalr	-1720(ra) # 80001a4a <myproc>
}
    8000310a:	5908                	lw	a0,48(a0)
    8000310c:	60a2                	ld	ra,8(sp)
    8000310e:	6402                	ld	s0,0(sp)
    80003110:	0141                	addi	sp,sp,16
    80003112:	8082                	ret

0000000080003114 <sys_fork>:

uint64
sys_fork(void)
{
    80003114:	1141                	addi	sp,sp,-16
    80003116:	e406                	sd	ra,8(sp)
    80003118:	e022                	sd	s0,0(sp)
    8000311a:	0800                	addi	s0,sp,16
  return fork();
    8000311c:	fffff097          	auipc	ra,0xfffff
    80003120:	d4a080e7          	jalr	-694(ra) # 80001e66 <fork>
}
    80003124:	60a2                	ld	ra,8(sp)
    80003126:	6402                	ld	s0,0(sp)
    80003128:	0141                	addi	sp,sp,16
    8000312a:	8082                	ret

000000008000312c <sys_wait>:

uint64
sys_wait(void)
{
    8000312c:	1101                	addi	sp,sp,-32
    8000312e:	ec06                	sd	ra,24(sp)
    80003130:	e822                	sd	s0,16(sp)
    80003132:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003134:	fe840593          	addi	a1,s0,-24
    80003138:	4501                	li	a0,0
    8000313a:	00000097          	auipc	ra,0x0
    8000313e:	ec0080e7          	jalr	-320(ra) # 80002ffa <argaddr>
  return wait(p);
    80003142:	fe843503          	ld	a0,-24(s0)
    80003146:	fffff097          	auipc	ra,0xfffff
    8000314a:	45a080e7          	jalr	1114(ra) # 800025a0 <wait>
}
    8000314e:	60e2                	ld	ra,24(sp)
    80003150:	6442                	ld	s0,16(sp)
    80003152:	6105                	addi	sp,sp,32
    80003154:	8082                	ret

0000000080003156 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003156:	7179                	addi	sp,sp,-48
    80003158:	f406                	sd	ra,40(sp)
    8000315a:	f022                	sd	s0,32(sp)
    8000315c:	ec26                	sd	s1,24(sp)
    8000315e:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003160:	fdc40593          	addi	a1,s0,-36
    80003164:	4501                	li	a0,0
    80003166:	00000097          	auipc	ra,0x0
    8000316a:	e74080e7          	jalr	-396(ra) # 80002fda <argint>
  addr = myproc()->sz;
    8000316e:	fffff097          	auipc	ra,0xfffff
    80003172:	8dc080e7          	jalr	-1828(ra) # 80001a4a <myproc>
    80003176:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003178:	fdc42503          	lw	a0,-36(s0)
    8000317c:	fffff097          	auipc	ra,0xfffff
    80003180:	c8e080e7          	jalr	-882(ra) # 80001e0a <growproc>
    80003184:	00054863          	bltz	a0,80003194 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003188:	8526                	mv	a0,s1
    8000318a:	70a2                	ld	ra,40(sp)
    8000318c:	7402                	ld	s0,32(sp)
    8000318e:	64e2                	ld	s1,24(sp)
    80003190:	6145                	addi	sp,sp,48
    80003192:	8082                	ret
    return -1;
    80003194:	54fd                	li	s1,-1
    80003196:	bfcd                	j	80003188 <sys_sbrk+0x32>

0000000080003198 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003198:	7139                	addi	sp,sp,-64
    8000319a:	fc06                	sd	ra,56(sp)
    8000319c:	f822                	sd	s0,48(sp)
    8000319e:	f04a                	sd	s2,32(sp)
    800031a0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800031a2:	fcc40593          	addi	a1,s0,-52
    800031a6:	4501                	li	a0,0
    800031a8:	00000097          	auipc	ra,0x0
    800031ac:	e32080e7          	jalr	-462(ra) # 80002fda <argint>
  acquire(&tickslock);
    800031b0:	00019517          	auipc	a0,0x19
    800031b4:	0a050513          	addi	a0,a0,160 # 8001c250 <tickslock>
    800031b8:	ffffe097          	auipc	ra,0xffffe
    800031bc:	a80080e7          	jalr	-1408(ra) # 80000c38 <acquire>
  ticks0 = ticks;
    800031c0:	00008917          	auipc	s2,0x8
    800031c4:	1f092903          	lw	s2,496(s2) # 8000b3b0 <ticks>
  while (ticks - ticks0 < n)
    800031c8:	fcc42783          	lw	a5,-52(s0)
    800031cc:	c3b9                	beqz	a5,80003212 <sys_sleep+0x7a>
    800031ce:	f426                	sd	s1,40(sp)
    800031d0:	ec4e                	sd	s3,24(sp)
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800031d2:	00019997          	auipc	s3,0x19
    800031d6:	07e98993          	addi	s3,s3,126 # 8001c250 <tickslock>
    800031da:	00008497          	auipc	s1,0x8
    800031de:	1d648493          	addi	s1,s1,470 # 8000b3b0 <ticks>
    if (killed(myproc()))
    800031e2:	fffff097          	auipc	ra,0xfffff
    800031e6:	868080e7          	jalr	-1944(ra) # 80001a4a <myproc>
    800031ea:	fffff097          	auipc	ra,0xfffff
    800031ee:	384080e7          	jalr	900(ra) # 8000256e <killed>
    800031f2:	ed15                	bnez	a0,8000322e <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800031f4:	85ce                	mv	a1,s3
    800031f6:	8526                	mv	a0,s1
    800031f8:	fffff097          	auipc	ra,0xfffff
    800031fc:	0b6080e7          	jalr	182(ra) # 800022ae <sleep>
  while (ticks - ticks0 < n)
    80003200:	409c                	lw	a5,0(s1)
    80003202:	412787bb          	subw	a5,a5,s2
    80003206:	fcc42703          	lw	a4,-52(s0)
    8000320a:	fce7ece3          	bltu	a5,a4,800031e2 <sys_sleep+0x4a>
    8000320e:	74a2                	ld	s1,40(sp)
    80003210:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80003212:	00019517          	auipc	a0,0x19
    80003216:	03e50513          	addi	a0,a0,62 # 8001c250 <tickslock>
    8000321a:	ffffe097          	auipc	ra,0xffffe
    8000321e:	ad2080e7          	jalr	-1326(ra) # 80000cec <release>
  return 0;
    80003222:	4501                	li	a0,0
}
    80003224:	70e2                	ld	ra,56(sp)
    80003226:	7442                	ld	s0,48(sp)
    80003228:	7902                	ld	s2,32(sp)
    8000322a:	6121                	addi	sp,sp,64
    8000322c:	8082                	ret
      release(&tickslock);
    8000322e:	00019517          	auipc	a0,0x19
    80003232:	02250513          	addi	a0,a0,34 # 8001c250 <tickslock>
    80003236:	ffffe097          	auipc	ra,0xffffe
    8000323a:	ab6080e7          	jalr	-1354(ra) # 80000cec <release>
      return -1;
    8000323e:	557d                	li	a0,-1
    80003240:	74a2                	ld	s1,40(sp)
    80003242:	69e2                	ld	s3,24(sp)
    80003244:	b7c5                	j	80003224 <sys_sleep+0x8c>

0000000080003246 <sys_kill>:

uint64
sys_kill(void)
{
    80003246:	1101                	addi	sp,sp,-32
    80003248:	ec06                	sd	ra,24(sp)
    8000324a:	e822                	sd	s0,16(sp)
    8000324c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000324e:	fec40593          	addi	a1,s0,-20
    80003252:	4501                	li	a0,0
    80003254:	00000097          	auipc	ra,0x0
    80003258:	d86080e7          	jalr	-634(ra) # 80002fda <argint>
  return kill(pid);
    8000325c:	fec42503          	lw	a0,-20(s0)
    80003260:	fffff097          	auipc	ra,0xfffff
    80003264:	270080e7          	jalr	624(ra) # 800024d0 <kill>
}
    80003268:	60e2                	ld	ra,24(sp)
    8000326a:	6442                	ld	s0,16(sp)
    8000326c:	6105                	addi	sp,sp,32
    8000326e:	8082                	ret

0000000080003270 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003270:	1101                	addi	sp,sp,-32
    80003272:	ec06                	sd	ra,24(sp)
    80003274:	e822                	sd	s0,16(sp)
    80003276:	e426                	sd	s1,8(sp)
    80003278:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000327a:	00019517          	auipc	a0,0x19
    8000327e:	fd650513          	addi	a0,a0,-42 # 8001c250 <tickslock>
    80003282:	ffffe097          	auipc	ra,0xffffe
    80003286:	9b6080e7          	jalr	-1610(ra) # 80000c38 <acquire>
  xticks = ticks;
    8000328a:	00008497          	auipc	s1,0x8
    8000328e:	1264a483          	lw	s1,294(s1) # 8000b3b0 <ticks>
  release(&tickslock);
    80003292:	00019517          	auipc	a0,0x19
    80003296:	fbe50513          	addi	a0,a0,-66 # 8001c250 <tickslock>
    8000329a:	ffffe097          	auipc	ra,0xffffe
    8000329e:	a52080e7          	jalr	-1454(ra) # 80000cec <release>
  return xticks;
}
    800032a2:	02049513          	slli	a0,s1,0x20
    800032a6:	9101                	srli	a0,a0,0x20
    800032a8:	60e2                	ld	ra,24(sp)
    800032aa:	6442                	ld	s0,16(sp)
    800032ac:	64a2                	ld	s1,8(sp)
    800032ae:	6105                	addi	sp,sp,32
    800032b0:	8082                	ret

00000000800032b2 <sys_waitx>:

uint64
sys_waitx(void)
{
    800032b2:	7139                	addi	sp,sp,-64
    800032b4:	fc06                	sd	ra,56(sp)
    800032b6:	f822                	sd	s0,48(sp)
    800032b8:	f426                	sd	s1,40(sp)
    800032ba:	f04a                	sd	s2,32(sp)
    800032bc:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800032be:	fd840593          	addi	a1,s0,-40
    800032c2:	4501                	li	a0,0
    800032c4:	00000097          	auipc	ra,0x0
    800032c8:	d36080e7          	jalr	-714(ra) # 80002ffa <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800032cc:	fd040593          	addi	a1,s0,-48
    800032d0:	4505                	li	a0,1
    800032d2:	00000097          	auipc	ra,0x0
    800032d6:	d28080e7          	jalr	-728(ra) # 80002ffa <argaddr>
  argaddr(2, &addr2);
    800032da:	fc840593          	addi	a1,s0,-56
    800032de:	4509                	li	a0,2
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	d1a080e7          	jalr	-742(ra) # 80002ffa <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800032e8:	fc040613          	addi	a2,s0,-64
    800032ec:	fc440593          	addi	a1,s0,-60
    800032f0:	fd843503          	ld	a0,-40(s0)
    800032f4:	fffff097          	auipc	ra,0xfffff
    800032f8:	55a080e7          	jalr	1370(ra) # 8000284e <waitx>
    800032fc:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800032fe:	ffffe097          	auipc	ra,0xffffe
    80003302:	74c080e7          	jalr	1868(ra) # 80001a4a <myproc>
    80003306:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003308:	4691                	li	a3,4
    8000330a:	fc440613          	addi	a2,s0,-60
    8000330e:	fd043583          	ld	a1,-48(s0)
    80003312:	6928                	ld	a0,80(a0)
    80003314:	ffffe097          	auipc	ra,0xffffe
    80003318:	3ce080e7          	jalr	974(ra) # 800016e2 <copyout>
    return -1;
    8000331c:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000331e:	00054f63          	bltz	a0,8000333c <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003322:	4691                	li	a3,4
    80003324:	fc040613          	addi	a2,s0,-64
    80003328:	fc843583          	ld	a1,-56(s0)
    8000332c:	68a8                	ld	a0,80(s1)
    8000332e:	ffffe097          	auipc	ra,0xffffe
    80003332:	3b4080e7          	jalr	948(ra) # 800016e2 <copyout>
    80003336:	00054a63          	bltz	a0,8000334a <sys_waitx+0x98>
    return -1;
  return ret;
    8000333a:	87ca                	mv	a5,s2
}
    8000333c:	853e                	mv	a0,a5
    8000333e:	70e2                	ld	ra,56(sp)
    80003340:	7442                	ld	s0,48(sp)
    80003342:	74a2                	ld	s1,40(sp)
    80003344:	7902                	ld	s2,32(sp)
    80003346:	6121                	addi	sp,sp,64
    80003348:	8082                	ret
    return -1;
    8000334a:	57fd                	li	a5,-1
    8000334c:	bfc5                	j	8000333c <sys_waitx+0x8a>

000000008000334e <sys_getSysCount>:

uint64
sys_getSysCount(void) {
    8000334e:	1101                	addi	sp,sp,-32
    80003350:	ec06                	sd	ra,24(sp)
    80003352:	e822                	sd	s0,16(sp)
    80003354:	1000                	addi	s0,sp,32
  int mask;
  argint(0, &mask);
    80003356:	fec40593          	addi	a1,s0,-20
    8000335a:	4501                	li	a0,0
    8000335c:	00000097          	auipc	ra,0x0
    80003360:	c7e080e7          	jalr	-898(ra) # 80002fda <argint>
  return getSysCount(mask);
    80003364:	fec42503          	lw	a0,-20(s0)
    80003368:	fffff097          	auipc	ra,0xfffff
    8000336c:	6a6080e7          	jalr	1702(ra) # 80002a0e <getSysCount>
}
    80003370:	60e2                	ld	ra,24(sp)
    80003372:	6442                	ld	s0,16(sp)
    80003374:	6105                	addi	sp,sp,32
    80003376:	8082                	ret

0000000080003378 <sys_sigalarm>:

uint64
sys_sigalarm(void) {
    80003378:	1101                	addi	sp,sp,-32
    8000337a:	ec06                	sd	ra,24(sp)
    8000337c:	e822                	sd	s0,16(sp)
    8000337e:	1000                	addi	s0,sp,32
    int interval;
    void (*handler)();

    // Get the arguments from the user
    argint(0, &interval);
    80003380:	fec40593          	addi	a1,s0,-20
    80003384:	4501                	li	a0,0
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	c54080e7          	jalr	-940(ra) # 80002fda <argint>
    argaddr(1, (uint64*)&handler);
    8000338e:	fe040593          	addi	a1,s0,-32
    80003392:	4505                	li	a0,1
    80003394:	00000097          	auipc	ra,0x0
    80003398:	c66080e7          	jalr	-922(ra) # 80002ffa <argaddr>
    struct proc *p = myproc();  // Get current process
    8000339c:	ffffe097          	auipc	ra,0xffffe
    800033a0:	6ae080e7          	jalr	1710(ra) # 80001a4a <myproc>
    p->alarmticks = interval;
    800033a4:	fec42783          	lw	a5,-20(s0)
    800033a8:	1ef52823          	sw	a5,496(a0)
    p->ticks_left = interval;
    800033ac:	1ef52a23          	sw	a5,500(a0)
    p->alarm_handler = handler;
    800033b0:	fe043783          	ld	a5,-32(s0)
    800033b4:	1ef53c23          	sd	a5,504(a0)
    p->in_alarm = 0; // Ensure we are not inside an alarm handler yet
    800033b8:	20052423          	sw	zero,520(a0)

    return 0;
}
    800033bc:	4501                	li	a0,0
    800033be:	60e2                	ld	ra,24(sp)
    800033c0:	6442                	ld	s0,16(sp)
    800033c2:	6105                	addi	sp,sp,32
    800033c4:	8082                	ret

00000000800033c6 <sys_sigreturn>:

uint64
sys_sigreturn(void) {
    800033c6:	1101                	addi	sp,sp,-32
    800033c8:	ec06                	sd	ra,24(sp)
    800033ca:	e822                	sd	s0,16(sp)
    800033cc:	e426                	sd	s1,8(sp)
    800033ce:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800033d0:	ffffe097          	auipc	ra,0xffffe
    800033d4:	67a080e7          	jalr	1658(ra) # 80001a4a <myproc>
    800033d8:	84aa                	mv	s1,a0

    // Restore the original trapframe to resume the process as it was before the handler
    memmove(p->trapframe, p->original_trapframe, sizeof(struct trapframe));
    800033da:	12000613          	li	a2,288
    800033de:	20053583          	ld	a1,512(a0)
    800033e2:	6d28                	ld	a0,88(a0)
    800033e4:	ffffe097          	auipc	ra,0xffffe
    800033e8:	9ac080e7          	jalr	-1620(ra) # 80000d90 <memmove>
    struct trapframe *tf = p->original_trapframe;
    800033ec:	2004b783          	ld	a5,512(s1)
    // Restore the registers from the original trapframe
    // Restore a0
    asm volatile("mv a0, %0" : : "r"(tf->a0));
    800033f0:	7bb8                	ld	a4,112(a5)
    800033f2:	853a                	mv	a0,a4
    // Restore other registers as necessary
    asm volatile("mv a1, %0" : : "r"(tf->a1));
    800033f4:	7fb8                	ld	a4,120(a5)
    800033f6:	85ba                	mv	a1,a4
    asm volatile("mv a2, %0" : : "r"(tf->a2));
    800033f8:	63d8                	ld	a4,128(a5)
    800033fa:	863a                	mv	a2,a4
    // Continue for other registers...

    // Restore the program counter
    asm volatile("mv ra, %0" : : "r"(tf->ra));
    800033fc:	779c                	ld	a5,40(a5)
    800033fe:	80be                	mv	ra,a5
    uint64 a0;
    asm volatile("mv %0, a0" : "=r"(a0));
    80003400:	852a                	mv	a0,a0

    p->in_alarm = 0;  // Reset the alarm state
    80003402:	2004a423          	sw	zero,520(s1)

    return a0;
}
    80003406:	60e2                	ld	ra,24(sp)
    80003408:	6442                	ld	s0,16(sp)
    8000340a:	64a2                	ld	s1,8(sp)
    8000340c:	6105                	addi	sp,sp,32
    8000340e:	8082                	ret

0000000080003410 <sys_settickets>:

uint64
sys_settickets(void) {
    80003410:	1101                	addi	sp,sp,-32
    80003412:	ec06                	sd	ra,24(sp)
    80003414:	e822                	sd	s0,16(sp)
    80003416:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003418:	fec40593          	addi	a1,s0,-20
    8000341c:	4501                	li	a0,0
    8000341e:	00000097          	auipc	ra,0x0
    80003422:	bbc080e7          	jalr	-1092(ra) # 80002fda <argint>
  if(n < 1)
    80003426:	fec42783          	lw	a5,-20(s0)
    return -1;
    8000342a:	557d                	li	a0,-1
  if(n < 1)
    8000342c:	00f05b63          	blez	a5,80003442 <sys_settickets+0x32>
  struct proc *p = myproc();
    80003430:	ffffe097          	auipc	ra,0xffffe
    80003434:	61a080e7          	jalr	1562(ra) # 80001a4a <myproc>
  p->tickets = n;
    80003438:	fec42783          	lw	a5,-20(s0)
    8000343c:	20f52623          	sw	a5,524(a0)
  return n;
    80003440:	853e                	mv	a0,a5
}
    80003442:	60e2                	ld	ra,24(sp)
    80003444:	6442                	ld	s0,16(sp)
    80003446:	6105                	addi	sp,sp,32
    80003448:	8082                	ret

000000008000344a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000344a:	7179                	addi	sp,sp,-48
    8000344c:	f406                	sd	ra,40(sp)
    8000344e:	f022                	sd	s0,32(sp)
    80003450:	ec26                	sd	s1,24(sp)
    80003452:	e84a                	sd	s2,16(sp)
    80003454:	e44e                	sd	s3,8(sp)
    80003456:	e052                	sd	s4,0(sp)
    80003458:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000345a:	00005597          	auipc	a1,0x5
    8000345e:	fa658593          	addi	a1,a1,-90 # 80008400 <etext+0x400>
    80003462:	00019517          	auipc	a0,0x19
    80003466:	e0650513          	addi	a0,a0,-506 # 8001c268 <bcache>
    8000346a:	ffffd097          	auipc	ra,0xffffd
    8000346e:	73e080e7          	jalr	1854(ra) # 80000ba8 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003472:	00021797          	auipc	a5,0x21
    80003476:	df678793          	addi	a5,a5,-522 # 80024268 <bcache+0x8000>
    8000347a:	00021717          	auipc	a4,0x21
    8000347e:	05670713          	addi	a4,a4,86 # 800244d0 <bcache+0x8268>
    80003482:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003486:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000348a:	00019497          	auipc	s1,0x19
    8000348e:	df648493          	addi	s1,s1,-522 # 8001c280 <bcache+0x18>
    b->next = bcache.head.next;
    80003492:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003494:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003496:	00005a17          	auipc	s4,0x5
    8000349a:	f72a0a13          	addi	s4,s4,-142 # 80008408 <etext+0x408>
    b->next = bcache.head.next;
    8000349e:	2b893783          	ld	a5,696(s2)
    800034a2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034a4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034a8:	85d2                	mv	a1,s4
    800034aa:	01048513          	addi	a0,s1,16
    800034ae:	00001097          	auipc	ra,0x1
    800034b2:	4e8080e7          	jalr	1256(ra) # 80004996 <initsleeplock>
    bcache.head.next->prev = b;
    800034b6:	2b893783          	ld	a5,696(s2)
    800034ba:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034bc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034c0:	45848493          	addi	s1,s1,1112
    800034c4:	fd349de3          	bne	s1,s3,8000349e <binit+0x54>
  }
}
    800034c8:	70a2                	ld	ra,40(sp)
    800034ca:	7402                	ld	s0,32(sp)
    800034cc:	64e2                	ld	s1,24(sp)
    800034ce:	6942                	ld	s2,16(sp)
    800034d0:	69a2                	ld	s3,8(sp)
    800034d2:	6a02                	ld	s4,0(sp)
    800034d4:	6145                	addi	sp,sp,48
    800034d6:	8082                	ret

00000000800034d8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800034d8:	7179                	addi	sp,sp,-48
    800034da:	f406                	sd	ra,40(sp)
    800034dc:	f022                	sd	s0,32(sp)
    800034de:	ec26                	sd	s1,24(sp)
    800034e0:	e84a                	sd	s2,16(sp)
    800034e2:	e44e                	sd	s3,8(sp)
    800034e4:	1800                	addi	s0,sp,48
    800034e6:	892a                	mv	s2,a0
    800034e8:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800034ea:	00019517          	auipc	a0,0x19
    800034ee:	d7e50513          	addi	a0,a0,-642 # 8001c268 <bcache>
    800034f2:	ffffd097          	auipc	ra,0xffffd
    800034f6:	746080e7          	jalr	1862(ra) # 80000c38 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800034fa:	00021497          	auipc	s1,0x21
    800034fe:	0264b483          	ld	s1,38(s1) # 80024520 <bcache+0x82b8>
    80003502:	00021797          	auipc	a5,0x21
    80003506:	fce78793          	addi	a5,a5,-50 # 800244d0 <bcache+0x8268>
    8000350a:	02f48f63          	beq	s1,a5,80003548 <bread+0x70>
    8000350e:	873e                	mv	a4,a5
    80003510:	a021                	j	80003518 <bread+0x40>
    80003512:	68a4                	ld	s1,80(s1)
    80003514:	02e48a63          	beq	s1,a4,80003548 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003518:	449c                	lw	a5,8(s1)
    8000351a:	ff279ce3          	bne	a5,s2,80003512 <bread+0x3a>
    8000351e:	44dc                	lw	a5,12(s1)
    80003520:	ff3799e3          	bne	a5,s3,80003512 <bread+0x3a>
      b->refcnt++;
    80003524:	40bc                	lw	a5,64(s1)
    80003526:	2785                	addiw	a5,a5,1
    80003528:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000352a:	00019517          	auipc	a0,0x19
    8000352e:	d3e50513          	addi	a0,a0,-706 # 8001c268 <bcache>
    80003532:	ffffd097          	auipc	ra,0xffffd
    80003536:	7ba080e7          	jalr	1978(ra) # 80000cec <release>
      acquiresleep(&b->lock);
    8000353a:	01048513          	addi	a0,s1,16
    8000353e:	00001097          	auipc	ra,0x1
    80003542:	492080e7          	jalr	1170(ra) # 800049d0 <acquiresleep>
      return b;
    80003546:	a8b9                	j	800035a4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003548:	00021497          	auipc	s1,0x21
    8000354c:	fd04b483          	ld	s1,-48(s1) # 80024518 <bcache+0x82b0>
    80003550:	00021797          	auipc	a5,0x21
    80003554:	f8078793          	addi	a5,a5,-128 # 800244d0 <bcache+0x8268>
    80003558:	00f48863          	beq	s1,a5,80003568 <bread+0x90>
    8000355c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000355e:	40bc                	lw	a5,64(s1)
    80003560:	cf81                	beqz	a5,80003578 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003562:	64a4                	ld	s1,72(s1)
    80003564:	fee49de3          	bne	s1,a4,8000355e <bread+0x86>
  panic("bget: no buffers");
    80003568:	00005517          	auipc	a0,0x5
    8000356c:	ea850513          	addi	a0,a0,-344 # 80008410 <etext+0x410>
    80003570:	ffffd097          	auipc	ra,0xffffd
    80003574:	ff0080e7          	jalr	-16(ra) # 80000560 <panic>
      b->dev = dev;
    80003578:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000357c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003580:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003584:	4785                	li	a5,1
    80003586:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003588:	00019517          	auipc	a0,0x19
    8000358c:	ce050513          	addi	a0,a0,-800 # 8001c268 <bcache>
    80003590:	ffffd097          	auipc	ra,0xffffd
    80003594:	75c080e7          	jalr	1884(ra) # 80000cec <release>
      acquiresleep(&b->lock);
    80003598:	01048513          	addi	a0,s1,16
    8000359c:	00001097          	auipc	ra,0x1
    800035a0:	434080e7          	jalr	1076(ra) # 800049d0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035a4:	409c                	lw	a5,0(s1)
    800035a6:	cb89                	beqz	a5,800035b8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035a8:	8526                	mv	a0,s1
    800035aa:	70a2                	ld	ra,40(sp)
    800035ac:	7402                	ld	s0,32(sp)
    800035ae:	64e2                	ld	s1,24(sp)
    800035b0:	6942                	ld	s2,16(sp)
    800035b2:	69a2                	ld	s3,8(sp)
    800035b4:	6145                	addi	sp,sp,48
    800035b6:	8082                	ret
    virtio_disk_rw(b, 0);
    800035b8:	4581                	li	a1,0
    800035ba:	8526                	mv	a0,s1
    800035bc:	00003097          	auipc	ra,0x3
    800035c0:	0ec080e7          	jalr	236(ra) # 800066a8 <virtio_disk_rw>
    b->valid = 1;
    800035c4:	4785                	li	a5,1
    800035c6:	c09c                	sw	a5,0(s1)
  return b;
    800035c8:	b7c5                	j	800035a8 <bread+0xd0>

00000000800035ca <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035ca:	1101                	addi	sp,sp,-32
    800035cc:	ec06                	sd	ra,24(sp)
    800035ce:	e822                	sd	s0,16(sp)
    800035d0:	e426                	sd	s1,8(sp)
    800035d2:	1000                	addi	s0,sp,32
    800035d4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035d6:	0541                	addi	a0,a0,16
    800035d8:	00001097          	auipc	ra,0x1
    800035dc:	492080e7          	jalr	1170(ra) # 80004a6a <holdingsleep>
    800035e0:	cd01                	beqz	a0,800035f8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800035e2:	4585                	li	a1,1
    800035e4:	8526                	mv	a0,s1
    800035e6:	00003097          	auipc	ra,0x3
    800035ea:	0c2080e7          	jalr	194(ra) # 800066a8 <virtio_disk_rw>
}
    800035ee:	60e2                	ld	ra,24(sp)
    800035f0:	6442                	ld	s0,16(sp)
    800035f2:	64a2                	ld	s1,8(sp)
    800035f4:	6105                	addi	sp,sp,32
    800035f6:	8082                	ret
    panic("bwrite");
    800035f8:	00005517          	auipc	a0,0x5
    800035fc:	e3050513          	addi	a0,a0,-464 # 80008428 <etext+0x428>
    80003600:	ffffd097          	auipc	ra,0xffffd
    80003604:	f60080e7          	jalr	-160(ra) # 80000560 <panic>

0000000080003608 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003608:	1101                	addi	sp,sp,-32
    8000360a:	ec06                	sd	ra,24(sp)
    8000360c:	e822                	sd	s0,16(sp)
    8000360e:	e426                	sd	s1,8(sp)
    80003610:	e04a                	sd	s2,0(sp)
    80003612:	1000                	addi	s0,sp,32
    80003614:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003616:	01050913          	addi	s2,a0,16
    8000361a:	854a                	mv	a0,s2
    8000361c:	00001097          	auipc	ra,0x1
    80003620:	44e080e7          	jalr	1102(ra) # 80004a6a <holdingsleep>
    80003624:	c925                	beqz	a0,80003694 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003626:	854a                	mv	a0,s2
    80003628:	00001097          	auipc	ra,0x1
    8000362c:	3fe080e7          	jalr	1022(ra) # 80004a26 <releasesleep>

  acquire(&bcache.lock);
    80003630:	00019517          	auipc	a0,0x19
    80003634:	c3850513          	addi	a0,a0,-968 # 8001c268 <bcache>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	600080e7          	jalr	1536(ra) # 80000c38 <acquire>
  b->refcnt--;
    80003640:	40bc                	lw	a5,64(s1)
    80003642:	37fd                	addiw	a5,a5,-1
    80003644:	0007871b          	sext.w	a4,a5
    80003648:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000364a:	e71d                	bnez	a4,80003678 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000364c:	68b8                	ld	a4,80(s1)
    8000364e:	64bc                	ld	a5,72(s1)
    80003650:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003652:	68b8                	ld	a4,80(s1)
    80003654:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003656:	00021797          	auipc	a5,0x21
    8000365a:	c1278793          	addi	a5,a5,-1006 # 80024268 <bcache+0x8000>
    8000365e:	2b87b703          	ld	a4,696(a5)
    80003662:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003664:	00021717          	auipc	a4,0x21
    80003668:	e6c70713          	addi	a4,a4,-404 # 800244d0 <bcache+0x8268>
    8000366c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000366e:	2b87b703          	ld	a4,696(a5)
    80003672:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003674:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003678:	00019517          	auipc	a0,0x19
    8000367c:	bf050513          	addi	a0,a0,-1040 # 8001c268 <bcache>
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	66c080e7          	jalr	1644(ra) # 80000cec <release>
}
    80003688:	60e2                	ld	ra,24(sp)
    8000368a:	6442                	ld	s0,16(sp)
    8000368c:	64a2                	ld	s1,8(sp)
    8000368e:	6902                	ld	s2,0(sp)
    80003690:	6105                	addi	sp,sp,32
    80003692:	8082                	ret
    panic("brelse");
    80003694:	00005517          	auipc	a0,0x5
    80003698:	d9c50513          	addi	a0,a0,-612 # 80008430 <etext+0x430>
    8000369c:	ffffd097          	auipc	ra,0xffffd
    800036a0:	ec4080e7          	jalr	-316(ra) # 80000560 <panic>

00000000800036a4 <bpin>:

void
bpin(struct buf *b) {
    800036a4:	1101                	addi	sp,sp,-32
    800036a6:	ec06                	sd	ra,24(sp)
    800036a8:	e822                	sd	s0,16(sp)
    800036aa:	e426                	sd	s1,8(sp)
    800036ac:	1000                	addi	s0,sp,32
    800036ae:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036b0:	00019517          	auipc	a0,0x19
    800036b4:	bb850513          	addi	a0,a0,-1096 # 8001c268 <bcache>
    800036b8:	ffffd097          	auipc	ra,0xffffd
    800036bc:	580080e7          	jalr	1408(ra) # 80000c38 <acquire>
  b->refcnt++;
    800036c0:	40bc                	lw	a5,64(s1)
    800036c2:	2785                	addiw	a5,a5,1
    800036c4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036c6:	00019517          	auipc	a0,0x19
    800036ca:	ba250513          	addi	a0,a0,-1118 # 8001c268 <bcache>
    800036ce:	ffffd097          	auipc	ra,0xffffd
    800036d2:	61e080e7          	jalr	1566(ra) # 80000cec <release>
}
    800036d6:	60e2                	ld	ra,24(sp)
    800036d8:	6442                	ld	s0,16(sp)
    800036da:	64a2                	ld	s1,8(sp)
    800036dc:	6105                	addi	sp,sp,32
    800036de:	8082                	ret

00000000800036e0 <bunpin>:

void
bunpin(struct buf *b) {
    800036e0:	1101                	addi	sp,sp,-32
    800036e2:	ec06                	sd	ra,24(sp)
    800036e4:	e822                	sd	s0,16(sp)
    800036e6:	e426                	sd	s1,8(sp)
    800036e8:	1000                	addi	s0,sp,32
    800036ea:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036ec:	00019517          	auipc	a0,0x19
    800036f0:	b7c50513          	addi	a0,a0,-1156 # 8001c268 <bcache>
    800036f4:	ffffd097          	auipc	ra,0xffffd
    800036f8:	544080e7          	jalr	1348(ra) # 80000c38 <acquire>
  b->refcnt--;
    800036fc:	40bc                	lw	a5,64(s1)
    800036fe:	37fd                	addiw	a5,a5,-1
    80003700:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003702:	00019517          	auipc	a0,0x19
    80003706:	b6650513          	addi	a0,a0,-1178 # 8001c268 <bcache>
    8000370a:	ffffd097          	auipc	ra,0xffffd
    8000370e:	5e2080e7          	jalr	1506(ra) # 80000cec <release>
}
    80003712:	60e2                	ld	ra,24(sp)
    80003714:	6442                	ld	s0,16(sp)
    80003716:	64a2                	ld	s1,8(sp)
    80003718:	6105                	addi	sp,sp,32
    8000371a:	8082                	ret

000000008000371c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000371c:	1101                	addi	sp,sp,-32
    8000371e:	ec06                	sd	ra,24(sp)
    80003720:	e822                	sd	s0,16(sp)
    80003722:	e426                	sd	s1,8(sp)
    80003724:	e04a                	sd	s2,0(sp)
    80003726:	1000                	addi	s0,sp,32
    80003728:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000372a:	00d5d59b          	srliw	a1,a1,0xd
    8000372e:	00021797          	auipc	a5,0x21
    80003732:	2167a783          	lw	a5,534(a5) # 80024944 <sb+0x1c>
    80003736:	9dbd                	addw	a1,a1,a5
    80003738:	00000097          	auipc	ra,0x0
    8000373c:	da0080e7          	jalr	-608(ra) # 800034d8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003740:	0074f713          	andi	a4,s1,7
    80003744:	4785                	li	a5,1
    80003746:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000374a:	14ce                	slli	s1,s1,0x33
    8000374c:	90d9                	srli	s1,s1,0x36
    8000374e:	00950733          	add	a4,a0,s1
    80003752:	05874703          	lbu	a4,88(a4)
    80003756:	00e7f6b3          	and	a3,a5,a4
    8000375a:	c69d                	beqz	a3,80003788 <bfree+0x6c>
    8000375c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000375e:	94aa                	add	s1,s1,a0
    80003760:	fff7c793          	not	a5,a5
    80003764:	8f7d                	and	a4,a4,a5
    80003766:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000376a:	00001097          	auipc	ra,0x1
    8000376e:	148080e7          	jalr	328(ra) # 800048b2 <log_write>
  brelse(bp);
    80003772:	854a                	mv	a0,s2
    80003774:	00000097          	auipc	ra,0x0
    80003778:	e94080e7          	jalr	-364(ra) # 80003608 <brelse>
}
    8000377c:	60e2                	ld	ra,24(sp)
    8000377e:	6442                	ld	s0,16(sp)
    80003780:	64a2                	ld	s1,8(sp)
    80003782:	6902                	ld	s2,0(sp)
    80003784:	6105                	addi	sp,sp,32
    80003786:	8082                	ret
    panic("freeing free block");
    80003788:	00005517          	auipc	a0,0x5
    8000378c:	cb050513          	addi	a0,a0,-848 # 80008438 <etext+0x438>
    80003790:	ffffd097          	auipc	ra,0xffffd
    80003794:	dd0080e7          	jalr	-560(ra) # 80000560 <panic>

0000000080003798 <balloc>:
{
    80003798:	711d                	addi	sp,sp,-96
    8000379a:	ec86                	sd	ra,88(sp)
    8000379c:	e8a2                	sd	s0,80(sp)
    8000379e:	e4a6                	sd	s1,72(sp)
    800037a0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037a2:	00021797          	auipc	a5,0x21
    800037a6:	18a7a783          	lw	a5,394(a5) # 8002492c <sb+0x4>
    800037aa:	10078f63          	beqz	a5,800038c8 <balloc+0x130>
    800037ae:	e0ca                	sd	s2,64(sp)
    800037b0:	fc4e                	sd	s3,56(sp)
    800037b2:	f852                	sd	s4,48(sp)
    800037b4:	f456                	sd	s5,40(sp)
    800037b6:	f05a                	sd	s6,32(sp)
    800037b8:	ec5e                	sd	s7,24(sp)
    800037ba:	e862                	sd	s8,16(sp)
    800037bc:	e466                	sd	s9,8(sp)
    800037be:	8baa                	mv	s7,a0
    800037c0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037c2:	00021b17          	auipc	s6,0x21
    800037c6:	166b0b13          	addi	s6,s6,358 # 80024928 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037ca:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037cc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037ce:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800037d0:	6c89                	lui	s9,0x2
    800037d2:	a061                	j	8000385a <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800037d4:	97ca                	add	a5,a5,s2
    800037d6:	8e55                	or	a2,a2,a3
    800037d8:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800037dc:	854a                	mv	a0,s2
    800037de:	00001097          	auipc	ra,0x1
    800037e2:	0d4080e7          	jalr	212(ra) # 800048b2 <log_write>
        brelse(bp);
    800037e6:	854a                	mv	a0,s2
    800037e8:	00000097          	auipc	ra,0x0
    800037ec:	e20080e7          	jalr	-480(ra) # 80003608 <brelse>
  bp = bread(dev, bno);
    800037f0:	85a6                	mv	a1,s1
    800037f2:	855e                	mv	a0,s7
    800037f4:	00000097          	auipc	ra,0x0
    800037f8:	ce4080e7          	jalr	-796(ra) # 800034d8 <bread>
    800037fc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800037fe:	40000613          	li	a2,1024
    80003802:	4581                	li	a1,0
    80003804:	05850513          	addi	a0,a0,88
    80003808:	ffffd097          	auipc	ra,0xffffd
    8000380c:	52c080e7          	jalr	1324(ra) # 80000d34 <memset>
  log_write(bp);
    80003810:	854a                	mv	a0,s2
    80003812:	00001097          	auipc	ra,0x1
    80003816:	0a0080e7          	jalr	160(ra) # 800048b2 <log_write>
  brelse(bp);
    8000381a:	854a                	mv	a0,s2
    8000381c:	00000097          	auipc	ra,0x0
    80003820:	dec080e7          	jalr	-532(ra) # 80003608 <brelse>
}
    80003824:	6906                	ld	s2,64(sp)
    80003826:	79e2                	ld	s3,56(sp)
    80003828:	7a42                	ld	s4,48(sp)
    8000382a:	7aa2                	ld	s5,40(sp)
    8000382c:	7b02                	ld	s6,32(sp)
    8000382e:	6be2                	ld	s7,24(sp)
    80003830:	6c42                	ld	s8,16(sp)
    80003832:	6ca2                	ld	s9,8(sp)
}
    80003834:	8526                	mv	a0,s1
    80003836:	60e6                	ld	ra,88(sp)
    80003838:	6446                	ld	s0,80(sp)
    8000383a:	64a6                	ld	s1,72(sp)
    8000383c:	6125                	addi	sp,sp,96
    8000383e:	8082                	ret
    brelse(bp);
    80003840:	854a                	mv	a0,s2
    80003842:	00000097          	auipc	ra,0x0
    80003846:	dc6080e7          	jalr	-570(ra) # 80003608 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000384a:	015c87bb          	addw	a5,s9,s5
    8000384e:	00078a9b          	sext.w	s5,a5
    80003852:	004b2703          	lw	a4,4(s6)
    80003856:	06eaf163          	bgeu	s5,a4,800038b8 <balloc+0x120>
    bp = bread(dev, BBLOCK(b, sb));
    8000385a:	41fad79b          	sraiw	a5,s5,0x1f
    8000385e:	0137d79b          	srliw	a5,a5,0x13
    80003862:	015787bb          	addw	a5,a5,s5
    80003866:	40d7d79b          	sraiw	a5,a5,0xd
    8000386a:	01cb2583          	lw	a1,28(s6)
    8000386e:	9dbd                	addw	a1,a1,a5
    80003870:	855e                	mv	a0,s7
    80003872:	00000097          	auipc	ra,0x0
    80003876:	c66080e7          	jalr	-922(ra) # 800034d8 <bread>
    8000387a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000387c:	004b2503          	lw	a0,4(s6)
    80003880:	000a849b          	sext.w	s1,s5
    80003884:	8762                	mv	a4,s8
    80003886:	faa4fde3          	bgeu	s1,a0,80003840 <balloc+0xa8>
      m = 1 << (bi % 8);
    8000388a:	00777693          	andi	a3,a4,7
    8000388e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003892:	41f7579b          	sraiw	a5,a4,0x1f
    80003896:	01d7d79b          	srliw	a5,a5,0x1d
    8000389a:	9fb9                	addw	a5,a5,a4
    8000389c:	4037d79b          	sraiw	a5,a5,0x3
    800038a0:	00f90633          	add	a2,s2,a5
    800038a4:	05864603          	lbu	a2,88(a2)
    800038a8:	00c6f5b3          	and	a1,a3,a2
    800038ac:	d585                	beqz	a1,800037d4 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038ae:	2705                	addiw	a4,a4,1
    800038b0:	2485                	addiw	s1,s1,1
    800038b2:	fd471ae3          	bne	a4,s4,80003886 <balloc+0xee>
    800038b6:	b769                	j	80003840 <balloc+0xa8>
    800038b8:	6906                	ld	s2,64(sp)
    800038ba:	79e2                	ld	s3,56(sp)
    800038bc:	7a42                	ld	s4,48(sp)
    800038be:	7aa2                	ld	s5,40(sp)
    800038c0:	7b02                	ld	s6,32(sp)
    800038c2:	6be2                	ld	s7,24(sp)
    800038c4:	6c42                	ld	s8,16(sp)
    800038c6:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    800038c8:	00005517          	auipc	a0,0x5
    800038cc:	b8850513          	addi	a0,a0,-1144 # 80008450 <etext+0x450>
    800038d0:	ffffd097          	auipc	ra,0xffffd
    800038d4:	cda080e7          	jalr	-806(ra) # 800005aa <printf>
  return 0;
    800038d8:	4481                	li	s1,0
    800038da:	bfa9                	j	80003834 <balloc+0x9c>

00000000800038dc <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800038dc:	7179                	addi	sp,sp,-48
    800038de:	f406                	sd	ra,40(sp)
    800038e0:	f022                	sd	s0,32(sp)
    800038e2:	ec26                	sd	s1,24(sp)
    800038e4:	e84a                	sd	s2,16(sp)
    800038e6:	e44e                	sd	s3,8(sp)
    800038e8:	1800                	addi	s0,sp,48
    800038ea:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800038ec:	47ad                	li	a5,11
    800038ee:	02b7e863          	bltu	a5,a1,8000391e <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800038f2:	02059793          	slli	a5,a1,0x20
    800038f6:	01e7d593          	srli	a1,a5,0x1e
    800038fa:	00b504b3          	add	s1,a0,a1
    800038fe:	0504a903          	lw	s2,80(s1)
    80003902:	08091263          	bnez	s2,80003986 <bmap+0xaa>
      addr = balloc(ip->dev);
    80003906:	4108                	lw	a0,0(a0)
    80003908:	00000097          	auipc	ra,0x0
    8000390c:	e90080e7          	jalr	-368(ra) # 80003798 <balloc>
    80003910:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003914:	06090963          	beqz	s2,80003986 <bmap+0xaa>
        return 0;
      ip->addrs[bn] = addr;
    80003918:	0524a823          	sw	s2,80(s1)
    8000391c:	a0ad                	j	80003986 <bmap+0xaa>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000391e:	ff45849b          	addiw	s1,a1,-12
    80003922:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003926:	0ff00793          	li	a5,255
    8000392a:	08e7e863          	bltu	a5,a4,800039ba <bmap+0xde>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000392e:	08052903          	lw	s2,128(a0)
    80003932:	00091f63          	bnez	s2,80003950 <bmap+0x74>
      addr = balloc(ip->dev);
    80003936:	4108                	lw	a0,0(a0)
    80003938:	00000097          	auipc	ra,0x0
    8000393c:	e60080e7          	jalr	-416(ra) # 80003798 <balloc>
    80003940:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003944:	04090163          	beqz	s2,80003986 <bmap+0xaa>
    80003948:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000394a:	0929a023          	sw	s2,128(s3)
    8000394e:	a011                	j	80003952 <bmap+0x76>
    80003950:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    80003952:	85ca                	mv	a1,s2
    80003954:	0009a503          	lw	a0,0(s3)
    80003958:	00000097          	auipc	ra,0x0
    8000395c:	b80080e7          	jalr	-1152(ra) # 800034d8 <bread>
    80003960:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003962:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003966:	02049713          	slli	a4,s1,0x20
    8000396a:	01e75593          	srli	a1,a4,0x1e
    8000396e:	00b784b3          	add	s1,a5,a1
    80003972:	0004a903          	lw	s2,0(s1)
    80003976:	02090063          	beqz	s2,80003996 <bmap+0xba>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000397a:	8552                	mv	a0,s4
    8000397c:	00000097          	auipc	ra,0x0
    80003980:	c8c080e7          	jalr	-884(ra) # 80003608 <brelse>
    return addr;
    80003984:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    80003986:	854a                	mv	a0,s2
    80003988:	70a2                	ld	ra,40(sp)
    8000398a:	7402                	ld	s0,32(sp)
    8000398c:	64e2                	ld	s1,24(sp)
    8000398e:	6942                	ld	s2,16(sp)
    80003990:	69a2                	ld	s3,8(sp)
    80003992:	6145                	addi	sp,sp,48
    80003994:	8082                	ret
      addr = balloc(ip->dev);
    80003996:	0009a503          	lw	a0,0(s3)
    8000399a:	00000097          	auipc	ra,0x0
    8000399e:	dfe080e7          	jalr	-514(ra) # 80003798 <balloc>
    800039a2:	0005091b          	sext.w	s2,a0
      if(addr){
    800039a6:	fc090ae3          	beqz	s2,8000397a <bmap+0x9e>
        a[bn] = addr;
    800039aa:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800039ae:	8552                	mv	a0,s4
    800039b0:	00001097          	auipc	ra,0x1
    800039b4:	f02080e7          	jalr	-254(ra) # 800048b2 <log_write>
    800039b8:	b7c9                	j	8000397a <bmap+0x9e>
    800039ba:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    800039bc:	00005517          	auipc	a0,0x5
    800039c0:	aac50513          	addi	a0,a0,-1364 # 80008468 <etext+0x468>
    800039c4:	ffffd097          	auipc	ra,0xffffd
    800039c8:	b9c080e7          	jalr	-1124(ra) # 80000560 <panic>

00000000800039cc <iget>:
{
    800039cc:	7179                	addi	sp,sp,-48
    800039ce:	f406                	sd	ra,40(sp)
    800039d0:	f022                	sd	s0,32(sp)
    800039d2:	ec26                	sd	s1,24(sp)
    800039d4:	e84a                	sd	s2,16(sp)
    800039d6:	e44e                	sd	s3,8(sp)
    800039d8:	e052                	sd	s4,0(sp)
    800039da:	1800                	addi	s0,sp,48
    800039dc:	89aa                	mv	s3,a0
    800039de:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039e0:	00021517          	auipc	a0,0x21
    800039e4:	f6850513          	addi	a0,a0,-152 # 80024948 <itable>
    800039e8:	ffffd097          	auipc	ra,0xffffd
    800039ec:	250080e7          	jalr	592(ra) # 80000c38 <acquire>
  empty = 0;
    800039f0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039f2:	00021497          	auipc	s1,0x21
    800039f6:	f6e48493          	addi	s1,s1,-146 # 80024960 <itable+0x18>
    800039fa:	00023697          	auipc	a3,0x23
    800039fe:	9f668693          	addi	a3,a3,-1546 # 800263f0 <log>
    80003a02:	a039                	j	80003a10 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a04:	02090b63          	beqz	s2,80003a3a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a08:	08848493          	addi	s1,s1,136
    80003a0c:	02d48a63          	beq	s1,a3,80003a40 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a10:	449c                	lw	a5,8(s1)
    80003a12:	fef059e3          	blez	a5,80003a04 <iget+0x38>
    80003a16:	4098                	lw	a4,0(s1)
    80003a18:	ff3716e3          	bne	a4,s3,80003a04 <iget+0x38>
    80003a1c:	40d8                	lw	a4,4(s1)
    80003a1e:	ff4713e3          	bne	a4,s4,80003a04 <iget+0x38>
      ip->ref++;
    80003a22:	2785                	addiw	a5,a5,1
    80003a24:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a26:	00021517          	auipc	a0,0x21
    80003a2a:	f2250513          	addi	a0,a0,-222 # 80024948 <itable>
    80003a2e:	ffffd097          	auipc	ra,0xffffd
    80003a32:	2be080e7          	jalr	702(ra) # 80000cec <release>
      return ip;
    80003a36:	8926                	mv	s2,s1
    80003a38:	a03d                	j	80003a66 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a3a:	f7f9                	bnez	a5,80003a08 <iget+0x3c>
      empty = ip;
    80003a3c:	8926                	mv	s2,s1
    80003a3e:	b7e9                	j	80003a08 <iget+0x3c>
  if(empty == 0)
    80003a40:	02090c63          	beqz	s2,80003a78 <iget+0xac>
  ip->dev = dev;
    80003a44:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a48:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a4c:	4785                	li	a5,1
    80003a4e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a52:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a56:	00021517          	auipc	a0,0x21
    80003a5a:	ef250513          	addi	a0,a0,-270 # 80024948 <itable>
    80003a5e:	ffffd097          	auipc	ra,0xffffd
    80003a62:	28e080e7          	jalr	654(ra) # 80000cec <release>
}
    80003a66:	854a                	mv	a0,s2
    80003a68:	70a2                	ld	ra,40(sp)
    80003a6a:	7402                	ld	s0,32(sp)
    80003a6c:	64e2                	ld	s1,24(sp)
    80003a6e:	6942                	ld	s2,16(sp)
    80003a70:	69a2                	ld	s3,8(sp)
    80003a72:	6a02                	ld	s4,0(sp)
    80003a74:	6145                	addi	sp,sp,48
    80003a76:	8082                	ret
    panic("iget: no inodes");
    80003a78:	00005517          	auipc	a0,0x5
    80003a7c:	a0850513          	addi	a0,a0,-1528 # 80008480 <etext+0x480>
    80003a80:	ffffd097          	auipc	ra,0xffffd
    80003a84:	ae0080e7          	jalr	-1312(ra) # 80000560 <panic>

0000000080003a88 <fsinit>:
fsinit(int dev) {
    80003a88:	7179                	addi	sp,sp,-48
    80003a8a:	f406                	sd	ra,40(sp)
    80003a8c:	f022                	sd	s0,32(sp)
    80003a8e:	ec26                	sd	s1,24(sp)
    80003a90:	e84a                	sd	s2,16(sp)
    80003a92:	e44e                	sd	s3,8(sp)
    80003a94:	1800                	addi	s0,sp,48
    80003a96:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a98:	4585                	li	a1,1
    80003a9a:	00000097          	auipc	ra,0x0
    80003a9e:	a3e080e7          	jalr	-1474(ra) # 800034d8 <bread>
    80003aa2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003aa4:	00021997          	auipc	s3,0x21
    80003aa8:	e8498993          	addi	s3,s3,-380 # 80024928 <sb>
    80003aac:	02000613          	li	a2,32
    80003ab0:	05850593          	addi	a1,a0,88
    80003ab4:	854e                	mv	a0,s3
    80003ab6:	ffffd097          	auipc	ra,0xffffd
    80003aba:	2da080e7          	jalr	730(ra) # 80000d90 <memmove>
  brelse(bp);
    80003abe:	8526                	mv	a0,s1
    80003ac0:	00000097          	auipc	ra,0x0
    80003ac4:	b48080e7          	jalr	-1208(ra) # 80003608 <brelse>
  if(sb.magic != FSMAGIC)
    80003ac8:	0009a703          	lw	a4,0(s3)
    80003acc:	102037b7          	lui	a5,0x10203
    80003ad0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ad4:	02f71263          	bne	a4,a5,80003af8 <fsinit+0x70>
  initlog(dev, &sb);
    80003ad8:	00021597          	auipc	a1,0x21
    80003adc:	e5058593          	addi	a1,a1,-432 # 80024928 <sb>
    80003ae0:	854a                	mv	a0,s2
    80003ae2:	00001097          	auipc	ra,0x1
    80003ae6:	b60080e7          	jalr	-1184(ra) # 80004642 <initlog>
}
    80003aea:	70a2                	ld	ra,40(sp)
    80003aec:	7402                	ld	s0,32(sp)
    80003aee:	64e2                	ld	s1,24(sp)
    80003af0:	6942                	ld	s2,16(sp)
    80003af2:	69a2                	ld	s3,8(sp)
    80003af4:	6145                	addi	sp,sp,48
    80003af6:	8082                	ret
    panic("invalid file system");
    80003af8:	00005517          	auipc	a0,0x5
    80003afc:	99850513          	addi	a0,a0,-1640 # 80008490 <etext+0x490>
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	a60080e7          	jalr	-1440(ra) # 80000560 <panic>

0000000080003b08 <iinit>:
{
    80003b08:	7179                	addi	sp,sp,-48
    80003b0a:	f406                	sd	ra,40(sp)
    80003b0c:	f022                	sd	s0,32(sp)
    80003b0e:	ec26                	sd	s1,24(sp)
    80003b10:	e84a                	sd	s2,16(sp)
    80003b12:	e44e                	sd	s3,8(sp)
    80003b14:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b16:	00005597          	auipc	a1,0x5
    80003b1a:	99258593          	addi	a1,a1,-1646 # 800084a8 <etext+0x4a8>
    80003b1e:	00021517          	auipc	a0,0x21
    80003b22:	e2a50513          	addi	a0,a0,-470 # 80024948 <itable>
    80003b26:	ffffd097          	auipc	ra,0xffffd
    80003b2a:	082080e7          	jalr	130(ra) # 80000ba8 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b2e:	00021497          	auipc	s1,0x21
    80003b32:	e4248493          	addi	s1,s1,-446 # 80024970 <itable+0x28>
    80003b36:	00023997          	auipc	s3,0x23
    80003b3a:	8ca98993          	addi	s3,s3,-1846 # 80026400 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b3e:	00005917          	auipc	s2,0x5
    80003b42:	97290913          	addi	s2,s2,-1678 # 800084b0 <etext+0x4b0>
    80003b46:	85ca                	mv	a1,s2
    80003b48:	8526                	mv	a0,s1
    80003b4a:	00001097          	auipc	ra,0x1
    80003b4e:	e4c080e7          	jalr	-436(ra) # 80004996 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b52:	08848493          	addi	s1,s1,136
    80003b56:	ff3498e3          	bne	s1,s3,80003b46 <iinit+0x3e>
}
    80003b5a:	70a2                	ld	ra,40(sp)
    80003b5c:	7402                	ld	s0,32(sp)
    80003b5e:	64e2                	ld	s1,24(sp)
    80003b60:	6942                	ld	s2,16(sp)
    80003b62:	69a2                	ld	s3,8(sp)
    80003b64:	6145                	addi	sp,sp,48
    80003b66:	8082                	ret

0000000080003b68 <ialloc>:
{
    80003b68:	7139                	addi	sp,sp,-64
    80003b6a:	fc06                	sd	ra,56(sp)
    80003b6c:	f822                	sd	s0,48(sp)
    80003b6e:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b70:	00021717          	auipc	a4,0x21
    80003b74:	dc472703          	lw	a4,-572(a4) # 80024934 <sb+0xc>
    80003b78:	4785                	li	a5,1
    80003b7a:	06e7f463          	bgeu	a5,a4,80003be2 <ialloc+0x7a>
    80003b7e:	f426                	sd	s1,40(sp)
    80003b80:	f04a                	sd	s2,32(sp)
    80003b82:	ec4e                	sd	s3,24(sp)
    80003b84:	e852                	sd	s4,16(sp)
    80003b86:	e456                	sd	s5,8(sp)
    80003b88:	e05a                	sd	s6,0(sp)
    80003b8a:	8aaa                	mv	s5,a0
    80003b8c:	8b2e                	mv	s6,a1
    80003b8e:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b90:	00021a17          	auipc	s4,0x21
    80003b94:	d98a0a13          	addi	s4,s4,-616 # 80024928 <sb>
    80003b98:	00495593          	srli	a1,s2,0x4
    80003b9c:	018a2783          	lw	a5,24(s4)
    80003ba0:	9dbd                	addw	a1,a1,a5
    80003ba2:	8556                	mv	a0,s5
    80003ba4:	00000097          	auipc	ra,0x0
    80003ba8:	934080e7          	jalr	-1740(ra) # 800034d8 <bread>
    80003bac:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003bae:	05850993          	addi	s3,a0,88
    80003bb2:	00f97793          	andi	a5,s2,15
    80003bb6:	079a                	slli	a5,a5,0x6
    80003bb8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003bba:	00099783          	lh	a5,0(s3)
    80003bbe:	cf9d                	beqz	a5,80003bfc <ialloc+0x94>
    brelse(bp);
    80003bc0:	00000097          	auipc	ra,0x0
    80003bc4:	a48080e7          	jalr	-1464(ra) # 80003608 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bc8:	0905                	addi	s2,s2,1
    80003bca:	00ca2703          	lw	a4,12(s4)
    80003bce:	0009079b          	sext.w	a5,s2
    80003bd2:	fce7e3e3          	bltu	a5,a4,80003b98 <ialloc+0x30>
    80003bd6:	74a2                	ld	s1,40(sp)
    80003bd8:	7902                	ld	s2,32(sp)
    80003bda:	69e2                	ld	s3,24(sp)
    80003bdc:	6a42                	ld	s4,16(sp)
    80003bde:	6aa2                	ld	s5,8(sp)
    80003be0:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    80003be2:	00005517          	auipc	a0,0x5
    80003be6:	8d650513          	addi	a0,a0,-1834 # 800084b8 <etext+0x4b8>
    80003bea:	ffffd097          	auipc	ra,0xffffd
    80003bee:	9c0080e7          	jalr	-1600(ra) # 800005aa <printf>
  return 0;
    80003bf2:	4501                	li	a0,0
}
    80003bf4:	70e2                	ld	ra,56(sp)
    80003bf6:	7442                	ld	s0,48(sp)
    80003bf8:	6121                	addi	sp,sp,64
    80003bfa:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003bfc:	04000613          	li	a2,64
    80003c00:	4581                	li	a1,0
    80003c02:	854e                	mv	a0,s3
    80003c04:	ffffd097          	auipc	ra,0xffffd
    80003c08:	130080e7          	jalr	304(ra) # 80000d34 <memset>
      dip->type = type;
    80003c0c:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c10:	8526                	mv	a0,s1
    80003c12:	00001097          	auipc	ra,0x1
    80003c16:	ca0080e7          	jalr	-864(ra) # 800048b2 <log_write>
      brelse(bp);
    80003c1a:	8526                	mv	a0,s1
    80003c1c:	00000097          	auipc	ra,0x0
    80003c20:	9ec080e7          	jalr	-1556(ra) # 80003608 <brelse>
      return iget(dev, inum);
    80003c24:	0009059b          	sext.w	a1,s2
    80003c28:	8556                	mv	a0,s5
    80003c2a:	00000097          	auipc	ra,0x0
    80003c2e:	da2080e7          	jalr	-606(ra) # 800039cc <iget>
    80003c32:	74a2                	ld	s1,40(sp)
    80003c34:	7902                	ld	s2,32(sp)
    80003c36:	69e2                	ld	s3,24(sp)
    80003c38:	6a42                	ld	s4,16(sp)
    80003c3a:	6aa2                	ld	s5,8(sp)
    80003c3c:	6b02                	ld	s6,0(sp)
    80003c3e:	bf5d                	j	80003bf4 <ialloc+0x8c>

0000000080003c40 <iupdate>:
{
    80003c40:	1101                	addi	sp,sp,-32
    80003c42:	ec06                	sd	ra,24(sp)
    80003c44:	e822                	sd	s0,16(sp)
    80003c46:	e426                	sd	s1,8(sp)
    80003c48:	e04a                	sd	s2,0(sp)
    80003c4a:	1000                	addi	s0,sp,32
    80003c4c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c4e:	415c                	lw	a5,4(a0)
    80003c50:	0047d79b          	srliw	a5,a5,0x4
    80003c54:	00021597          	auipc	a1,0x21
    80003c58:	cec5a583          	lw	a1,-788(a1) # 80024940 <sb+0x18>
    80003c5c:	9dbd                	addw	a1,a1,a5
    80003c5e:	4108                	lw	a0,0(a0)
    80003c60:	00000097          	auipc	ra,0x0
    80003c64:	878080e7          	jalr	-1928(ra) # 800034d8 <bread>
    80003c68:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c6a:	05850793          	addi	a5,a0,88
    80003c6e:	40d8                	lw	a4,4(s1)
    80003c70:	8b3d                	andi	a4,a4,15
    80003c72:	071a                	slli	a4,a4,0x6
    80003c74:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003c76:	04449703          	lh	a4,68(s1)
    80003c7a:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003c7e:	04649703          	lh	a4,70(s1)
    80003c82:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003c86:	04849703          	lh	a4,72(s1)
    80003c8a:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003c8e:	04a49703          	lh	a4,74(s1)
    80003c92:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003c96:	44f8                	lw	a4,76(s1)
    80003c98:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c9a:	03400613          	li	a2,52
    80003c9e:	05048593          	addi	a1,s1,80
    80003ca2:	00c78513          	addi	a0,a5,12
    80003ca6:	ffffd097          	auipc	ra,0xffffd
    80003caa:	0ea080e7          	jalr	234(ra) # 80000d90 <memmove>
  log_write(bp);
    80003cae:	854a                	mv	a0,s2
    80003cb0:	00001097          	auipc	ra,0x1
    80003cb4:	c02080e7          	jalr	-1022(ra) # 800048b2 <log_write>
  brelse(bp);
    80003cb8:	854a                	mv	a0,s2
    80003cba:	00000097          	auipc	ra,0x0
    80003cbe:	94e080e7          	jalr	-1714(ra) # 80003608 <brelse>
}
    80003cc2:	60e2                	ld	ra,24(sp)
    80003cc4:	6442                	ld	s0,16(sp)
    80003cc6:	64a2                	ld	s1,8(sp)
    80003cc8:	6902                	ld	s2,0(sp)
    80003cca:	6105                	addi	sp,sp,32
    80003ccc:	8082                	ret

0000000080003cce <idup>:
{
    80003cce:	1101                	addi	sp,sp,-32
    80003cd0:	ec06                	sd	ra,24(sp)
    80003cd2:	e822                	sd	s0,16(sp)
    80003cd4:	e426                	sd	s1,8(sp)
    80003cd6:	1000                	addi	s0,sp,32
    80003cd8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cda:	00021517          	auipc	a0,0x21
    80003cde:	c6e50513          	addi	a0,a0,-914 # 80024948 <itable>
    80003ce2:	ffffd097          	auipc	ra,0xffffd
    80003ce6:	f56080e7          	jalr	-170(ra) # 80000c38 <acquire>
  ip->ref++;
    80003cea:	449c                	lw	a5,8(s1)
    80003cec:	2785                	addiw	a5,a5,1
    80003cee:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cf0:	00021517          	auipc	a0,0x21
    80003cf4:	c5850513          	addi	a0,a0,-936 # 80024948 <itable>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	ff4080e7          	jalr	-12(ra) # 80000cec <release>
}
    80003d00:	8526                	mv	a0,s1
    80003d02:	60e2                	ld	ra,24(sp)
    80003d04:	6442                	ld	s0,16(sp)
    80003d06:	64a2                	ld	s1,8(sp)
    80003d08:	6105                	addi	sp,sp,32
    80003d0a:	8082                	ret

0000000080003d0c <ilock>:
{
    80003d0c:	1101                	addi	sp,sp,-32
    80003d0e:	ec06                	sd	ra,24(sp)
    80003d10:	e822                	sd	s0,16(sp)
    80003d12:	e426                	sd	s1,8(sp)
    80003d14:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d16:	c10d                	beqz	a0,80003d38 <ilock+0x2c>
    80003d18:	84aa                	mv	s1,a0
    80003d1a:	451c                	lw	a5,8(a0)
    80003d1c:	00f05e63          	blez	a5,80003d38 <ilock+0x2c>
  acquiresleep(&ip->lock);
    80003d20:	0541                	addi	a0,a0,16
    80003d22:	00001097          	auipc	ra,0x1
    80003d26:	cae080e7          	jalr	-850(ra) # 800049d0 <acquiresleep>
  if(ip->valid == 0){
    80003d2a:	40bc                	lw	a5,64(s1)
    80003d2c:	cf99                	beqz	a5,80003d4a <ilock+0x3e>
}
    80003d2e:	60e2                	ld	ra,24(sp)
    80003d30:	6442                	ld	s0,16(sp)
    80003d32:	64a2                	ld	s1,8(sp)
    80003d34:	6105                	addi	sp,sp,32
    80003d36:	8082                	ret
    80003d38:	e04a                	sd	s2,0(sp)
    panic("ilock");
    80003d3a:	00004517          	auipc	a0,0x4
    80003d3e:	79650513          	addi	a0,a0,1942 # 800084d0 <etext+0x4d0>
    80003d42:	ffffd097          	auipc	ra,0xffffd
    80003d46:	81e080e7          	jalr	-2018(ra) # 80000560 <panic>
    80003d4a:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d4c:	40dc                	lw	a5,4(s1)
    80003d4e:	0047d79b          	srliw	a5,a5,0x4
    80003d52:	00021597          	auipc	a1,0x21
    80003d56:	bee5a583          	lw	a1,-1042(a1) # 80024940 <sb+0x18>
    80003d5a:	9dbd                	addw	a1,a1,a5
    80003d5c:	4088                	lw	a0,0(s1)
    80003d5e:	fffff097          	auipc	ra,0xfffff
    80003d62:	77a080e7          	jalr	1914(ra) # 800034d8 <bread>
    80003d66:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d68:	05850593          	addi	a1,a0,88
    80003d6c:	40dc                	lw	a5,4(s1)
    80003d6e:	8bbd                	andi	a5,a5,15
    80003d70:	079a                	slli	a5,a5,0x6
    80003d72:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d74:	00059783          	lh	a5,0(a1)
    80003d78:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d7c:	00259783          	lh	a5,2(a1)
    80003d80:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d84:	00459783          	lh	a5,4(a1)
    80003d88:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d8c:	00659783          	lh	a5,6(a1)
    80003d90:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d94:	459c                	lw	a5,8(a1)
    80003d96:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d98:	03400613          	li	a2,52
    80003d9c:	05b1                	addi	a1,a1,12
    80003d9e:	05048513          	addi	a0,s1,80
    80003da2:	ffffd097          	auipc	ra,0xffffd
    80003da6:	fee080e7          	jalr	-18(ra) # 80000d90 <memmove>
    brelse(bp);
    80003daa:	854a                	mv	a0,s2
    80003dac:	00000097          	auipc	ra,0x0
    80003db0:	85c080e7          	jalr	-1956(ra) # 80003608 <brelse>
    ip->valid = 1;
    80003db4:	4785                	li	a5,1
    80003db6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003db8:	04449783          	lh	a5,68(s1)
    80003dbc:	c399                	beqz	a5,80003dc2 <ilock+0xb6>
    80003dbe:	6902                	ld	s2,0(sp)
    80003dc0:	b7bd                	j	80003d2e <ilock+0x22>
      panic("ilock: no type");
    80003dc2:	00004517          	auipc	a0,0x4
    80003dc6:	71650513          	addi	a0,a0,1814 # 800084d8 <etext+0x4d8>
    80003dca:	ffffc097          	auipc	ra,0xffffc
    80003dce:	796080e7          	jalr	1942(ra) # 80000560 <panic>

0000000080003dd2 <iunlock>:
{
    80003dd2:	1101                	addi	sp,sp,-32
    80003dd4:	ec06                	sd	ra,24(sp)
    80003dd6:	e822                	sd	s0,16(sp)
    80003dd8:	e426                	sd	s1,8(sp)
    80003dda:	e04a                	sd	s2,0(sp)
    80003ddc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003dde:	c905                	beqz	a0,80003e0e <iunlock+0x3c>
    80003de0:	84aa                	mv	s1,a0
    80003de2:	01050913          	addi	s2,a0,16
    80003de6:	854a                	mv	a0,s2
    80003de8:	00001097          	auipc	ra,0x1
    80003dec:	c82080e7          	jalr	-894(ra) # 80004a6a <holdingsleep>
    80003df0:	cd19                	beqz	a0,80003e0e <iunlock+0x3c>
    80003df2:	449c                	lw	a5,8(s1)
    80003df4:	00f05d63          	blez	a5,80003e0e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003df8:	854a                	mv	a0,s2
    80003dfa:	00001097          	auipc	ra,0x1
    80003dfe:	c2c080e7          	jalr	-980(ra) # 80004a26 <releasesleep>
}
    80003e02:	60e2                	ld	ra,24(sp)
    80003e04:	6442                	ld	s0,16(sp)
    80003e06:	64a2                	ld	s1,8(sp)
    80003e08:	6902                	ld	s2,0(sp)
    80003e0a:	6105                	addi	sp,sp,32
    80003e0c:	8082                	ret
    panic("iunlock");
    80003e0e:	00004517          	auipc	a0,0x4
    80003e12:	6da50513          	addi	a0,a0,1754 # 800084e8 <etext+0x4e8>
    80003e16:	ffffc097          	auipc	ra,0xffffc
    80003e1a:	74a080e7          	jalr	1866(ra) # 80000560 <panic>

0000000080003e1e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e1e:	7179                	addi	sp,sp,-48
    80003e20:	f406                	sd	ra,40(sp)
    80003e22:	f022                	sd	s0,32(sp)
    80003e24:	ec26                	sd	s1,24(sp)
    80003e26:	e84a                	sd	s2,16(sp)
    80003e28:	e44e                	sd	s3,8(sp)
    80003e2a:	1800                	addi	s0,sp,48
    80003e2c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e2e:	05050493          	addi	s1,a0,80
    80003e32:	08050913          	addi	s2,a0,128
    80003e36:	a021                	j	80003e3e <itrunc+0x20>
    80003e38:	0491                	addi	s1,s1,4
    80003e3a:	01248d63          	beq	s1,s2,80003e54 <itrunc+0x36>
    if(ip->addrs[i]){
    80003e3e:	408c                	lw	a1,0(s1)
    80003e40:	dde5                	beqz	a1,80003e38 <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    80003e42:	0009a503          	lw	a0,0(s3)
    80003e46:	00000097          	auipc	ra,0x0
    80003e4a:	8d6080e7          	jalr	-1834(ra) # 8000371c <bfree>
      ip->addrs[i] = 0;
    80003e4e:	0004a023          	sw	zero,0(s1)
    80003e52:	b7dd                	j	80003e38 <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e54:	0809a583          	lw	a1,128(s3)
    80003e58:	ed99                	bnez	a1,80003e76 <itrunc+0x58>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e5a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e5e:	854e                	mv	a0,s3
    80003e60:	00000097          	auipc	ra,0x0
    80003e64:	de0080e7          	jalr	-544(ra) # 80003c40 <iupdate>
}
    80003e68:	70a2                	ld	ra,40(sp)
    80003e6a:	7402                	ld	s0,32(sp)
    80003e6c:	64e2                	ld	s1,24(sp)
    80003e6e:	6942                	ld	s2,16(sp)
    80003e70:	69a2                	ld	s3,8(sp)
    80003e72:	6145                	addi	sp,sp,48
    80003e74:	8082                	ret
    80003e76:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e78:	0009a503          	lw	a0,0(s3)
    80003e7c:	fffff097          	auipc	ra,0xfffff
    80003e80:	65c080e7          	jalr	1628(ra) # 800034d8 <bread>
    80003e84:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e86:	05850493          	addi	s1,a0,88
    80003e8a:	45850913          	addi	s2,a0,1112
    80003e8e:	a021                	j	80003e96 <itrunc+0x78>
    80003e90:	0491                	addi	s1,s1,4
    80003e92:	01248b63          	beq	s1,s2,80003ea8 <itrunc+0x8a>
      if(a[j])
    80003e96:	408c                	lw	a1,0(s1)
    80003e98:	dde5                	beqz	a1,80003e90 <itrunc+0x72>
        bfree(ip->dev, a[j]);
    80003e9a:	0009a503          	lw	a0,0(s3)
    80003e9e:	00000097          	auipc	ra,0x0
    80003ea2:	87e080e7          	jalr	-1922(ra) # 8000371c <bfree>
    80003ea6:	b7ed                	j	80003e90 <itrunc+0x72>
    brelse(bp);
    80003ea8:	8552                	mv	a0,s4
    80003eaa:	fffff097          	auipc	ra,0xfffff
    80003eae:	75e080e7          	jalr	1886(ra) # 80003608 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003eb2:	0809a583          	lw	a1,128(s3)
    80003eb6:	0009a503          	lw	a0,0(s3)
    80003eba:	00000097          	auipc	ra,0x0
    80003ebe:	862080e7          	jalr	-1950(ra) # 8000371c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ec2:	0809a023          	sw	zero,128(s3)
    80003ec6:	6a02                	ld	s4,0(sp)
    80003ec8:	bf49                	j	80003e5a <itrunc+0x3c>

0000000080003eca <iput>:
{
    80003eca:	1101                	addi	sp,sp,-32
    80003ecc:	ec06                	sd	ra,24(sp)
    80003ece:	e822                	sd	s0,16(sp)
    80003ed0:	e426                	sd	s1,8(sp)
    80003ed2:	1000                	addi	s0,sp,32
    80003ed4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ed6:	00021517          	auipc	a0,0x21
    80003eda:	a7250513          	addi	a0,a0,-1422 # 80024948 <itable>
    80003ede:	ffffd097          	auipc	ra,0xffffd
    80003ee2:	d5a080e7          	jalr	-678(ra) # 80000c38 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ee6:	4498                	lw	a4,8(s1)
    80003ee8:	4785                	li	a5,1
    80003eea:	02f70263          	beq	a4,a5,80003f0e <iput+0x44>
  ip->ref--;
    80003eee:	449c                	lw	a5,8(s1)
    80003ef0:	37fd                	addiw	a5,a5,-1
    80003ef2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ef4:	00021517          	auipc	a0,0x21
    80003ef8:	a5450513          	addi	a0,a0,-1452 # 80024948 <itable>
    80003efc:	ffffd097          	auipc	ra,0xffffd
    80003f00:	df0080e7          	jalr	-528(ra) # 80000cec <release>
}
    80003f04:	60e2                	ld	ra,24(sp)
    80003f06:	6442                	ld	s0,16(sp)
    80003f08:	64a2                	ld	s1,8(sp)
    80003f0a:	6105                	addi	sp,sp,32
    80003f0c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f0e:	40bc                	lw	a5,64(s1)
    80003f10:	dff9                	beqz	a5,80003eee <iput+0x24>
    80003f12:	04a49783          	lh	a5,74(s1)
    80003f16:	ffe1                	bnez	a5,80003eee <iput+0x24>
    80003f18:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    80003f1a:	01048913          	addi	s2,s1,16
    80003f1e:	854a                	mv	a0,s2
    80003f20:	00001097          	auipc	ra,0x1
    80003f24:	ab0080e7          	jalr	-1360(ra) # 800049d0 <acquiresleep>
    release(&itable.lock);
    80003f28:	00021517          	auipc	a0,0x21
    80003f2c:	a2050513          	addi	a0,a0,-1504 # 80024948 <itable>
    80003f30:	ffffd097          	auipc	ra,0xffffd
    80003f34:	dbc080e7          	jalr	-580(ra) # 80000cec <release>
    itrunc(ip);
    80003f38:	8526                	mv	a0,s1
    80003f3a:	00000097          	auipc	ra,0x0
    80003f3e:	ee4080e7          	jalr	-284(ra) # 80003e1e <itrunc>
    ip->type = 0;
    80003f42:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f46:	8526                	mv	a0,s1
    80003f48:	00000097          	auipc	ra,0x0
    80003f4c:	cf8080e7          	jalr	-776(ra) # 80003c40 <iupdate>
    ip->valid = 0;
    80003f50:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f54:	854a                	mv	a0,s2
    80003f56:	00001097          	auipc	ra,0x1
    80003f5a:	ad0080e7          	jalr	-1328(ra) # 80004a26 <releasesleep>
    acquire(&itable.lock);
    80003f5e:	00021517          	auipc	a0,0x21
    80003f62:	9ea50513          	addi	a0,a0,-1558 # 80024948 <itable>
    80003f66:	ffffd097          	auipc	ra,0xffffd
    80003f6a:	cd2080e7          	jalr	-814(ra) # 80000c38 <acquire>
    80003f6e:	6902                	ld	s2,0(sp)
    80003f70:	bfbd                	j	80003eee <iput+0x24>

0000000080003f72 <iunlockput>:
{
    80003f72:	1101                	addi	sp,sp,-32
    80003f74:	ec06                	sd	ra,24(sp)
    80003f76:	e822                	sd	s0,16(sp)
    80003f78:	e426                	sd	s1,8(sp)
    80003f7a:	1000                	addi	s0,sp,32
    80003f7c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	e54080e7          	jalr	-428(ra) # 80003dd2 <iunlock>
  iput(ip);
    80003f86:	8526                	mv	a0,s1
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	f42080e7          	jalr	-190(ra) # 80003eca <iput>
}
    80003f90:	60e2                	ld	ra,24(sp)
    80003f92:	6442                	ld	s0,16(sp)
    80003f94:	64a2                	ld	s1,8(sp)
    80003f96:	6105                	addi	sp,sp,32
    80003f98:	8082                	ret

0000000080003f9a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f9a:	1141                	addi	sp,sp,-16
    80003f9c:	e422                	sd	s0,8(sp)
    80003f9e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003fa0:	411c                	lw	a5,0(a0)
    80003fa2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003fa4:	415c                	lw	a5,4(a0)
    80003fa6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fa8:	04451783          	lh	a5,68(a0)
    80003fac:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003fb0:	04a51783          	lh	a5,74(a0)
    80003fb4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fb8:	04c56783          	lwu	a5,76(a0)
    80003fbc:	e99c                	sd	a5,16(a1)
}
    80003fbe:	6422                	ld	s0,8(sp)
    80003fc0:	0141                	addi	sp,sp,16
    80003fc2:	8082                	ret

0000000080003fc4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fc4:	457c                	lw	a5,76(a0)
    80003fc6:	10d7e563          	bltu	a5,a3,800040d0 <readi+0x10c>
{
    80003fca:	7159                	addi	sp,sp,-112
    80003fcc:	f486                	sd	ra,104(sp)
    80003fce:	f0a2                	sd	s0,96(sp)
    80003fd0:	eca6                	sd	s1,88(sp)
    80003fd2:	e0d2                	sd	s4,64(sp)
    80003fd4:	fc56                	sd	s5,56(sp)
    80003fd6:	f85a                	sd	s6,48(sp)
    80003fd8:	f45e                	sd	s7,40(sp)
    80003fda:	1880                	addi	s0,sp,112
    80003fdc:	8b2a                	mv	s6,a0
    80003fde:	8bae                	mv	s7,a1
    80003fe0:	8a32                	mv	s4,a2
    80003fe2:	84b6                	mv	s1,a3
    80003fe4:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003fe6:	9f35                	addw	a4,a4,a3
    return 0;
    80003fe8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003fea:	0cd76a63          	bltu	a4,a3,800040be <readi+0xfa>
    80003fee:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    80003ff0:	00e7f463          	bgeu	a5,a4,80003ff8 <readi+0x34>
    n = ip->size - off;
    80003ff4:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ff8:	0a0a8963          	beqz	s5,800040aa <readi+0xe6>
    80003ffc:	e8ca                	sd	s2,80(sp)
    80003ffe:	f062                	sd	s8,32(sp)
    80004000:	ec66                	sd	s9,24(sp)
    80004002:	e86a                	sd	s10,16(sp)
    80004004:	e46e                	sd	s11,8(sp)
    80004006:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004008:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000400c:	5c7d                	li	s8,-1
    8000400e:	a82d                	j	80004048 <readi+0x84>
    80004010:	020d1d93          	slli	s11,s10,0x20
    80004014:	020ddd93          	srli	s11,s11,0x20
    80004018:	05890613          	addi	a2,s2,88
    8000401c:	86ee                	mv	a3,s11
    8000401e:	963a                	add	a2,a2,a4
    80004020:	85d2                	mv	a1,s4
    80004022:	855e                	mv	a0,s7
    80004024:	ffffe097          	auipc	ra,0xffffe
    80004028:	6c6080e7          	jalr	1734(ra) # 800026ea <either_copyout>
    8000402c:	05850d63          	beq	a0,s8,80004086 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004030:	854a                	mv	a0,s2
    80004032:	fffff097          	auipc	ra,0xfffff
    80004036:	5d6080e7          	jalr	1494(ra) # 80003608 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000403a:	013d09bb          	addw	s3,s10,s3
    8000403e:	009d04bb          	addw	s1,s10,s1
    80004042:	9a6e                	add	s4,s4,s11
    80004044:	0559fd63          	bgeu	s3,s5,8000409e <readi+0xda>
    uint addr = bmap(ip, off/BSIZE);
    80004048:	00a4d59b          	srliw	a1,s1,0xa
    8000404c:	855a                	mv	a0,s6
    8000404e:	00000097          	auipc	ra,0x0
    80004052:	88e080e7          	jalr	-1906(ra) # 800038dc <bmap>
    80004056:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000405a:	c9b1                	beqz	a1,800040ae <readi+0xea>
    bp = bread(ip->dev, addr);
    8000405c:	000b2503          	lw	a0,0(s6)
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	478080e7          	jalr	1144(ra) # 800034d8 <bread>
    80004068:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000406a:	3ff4f713          	andi	a4,s1,1023
    8000406e:	40ec87bb          	subw	a5,s9,a4
    80004072:	413a86bb          	subw	a3,s5,s3
    80004076:	8d3e                	mv	s10,a5
    80004078:	2781                	sext.w	a5,a5
    8000407a:	0006861b          	sext.w	a2,a3
    8000407e:	f8f679e3          	bgeu	a2,a5,80004010 <readi+0x4c>
    80004082:	8d36                	mv	s10,a3
    80004084:	b771                	j	80004010 <readi+0x4c>
      brelse(bp);
    80004086:	854a                	mv	a0,s2
    80004088:	fffff097          	auipc	ra,0xfffff
    8000408c:	580080e7          	jalr	1408(ra) # 80003608 <brelse>
      tot = -1;
    80004090:	59fd                	li	s3,-1
      break;
    80004092:	6946                	ld	s2,80(sp)
    80004094:	7c02                	ld	s8,32(sp)
    80004096:	6ce2                	ld	s9,24(sp)
    80004098:	6d42                	ld	s10,16(sp)
    8000409a:	6da2                	ld	s11,8(sp)
    8000409c:	a831                	j	800040b8 <readi+0xf4>
    8000409e:	6946                	ld	s2,80(sp)
    800040a0:	7c02                	ld	s8,32(sp)
    800040a2:	6ce2                	ld	s9,24(sp)
    800040a4:	6d42                	ld	s10,16(sp)
    800040a6:	6da2                	ld	s11,8(sp)
    800040a8:	a801                	j	800040b8 <readi+0xf4>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040aa:	89d6                	mv	s3,s5
    800040ac:	a031                	j	800040b8 <readi+0xf4>
    800040ae:	6946                	ld	s2,80(sp)
    800040b0:	7c02                	ld	s8,32(sp)
    800040b2:	6ce2                	ld	s9,24(sp)
    800040b4:	6d42                	ld	s10,16(sp)
    800040b6:	6da2                	ld	s11,8(sp)
  }
  return tot;
    800040b8:	0009851b          	sext.w	a0,s3
    800040bc:	69a6                	ld	s3,72(sp)
}
    800040be:	70a6                	ld	ra,104(sp)
    800040c0:	7406                	ld	s0,96(sp)
    800040c2:	64e6                	ld	s1,88(sp)
    800040c4:	6a06                	ld	s4,64(sp)
    800040c6:	7ae2                	ld	s5,56(sp)
    800040c8:	7b42                	ld	s6,48(sp)
    800040ca:	7ba2                	ld	s7,40(sp)
    800040cc:	6165                	addi	sp,sp,112
    800040ce:	8082                	ret
    return 0;
    800040d0:	4501                	li	a0,0
}
    800040d2:	8082                	ret

00000000800040d4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040d4:	457c                	lw	a5,76(a0)
    800040d6:	10d7ee63          	bltu	a5,a3,800041f2 <writei+0x11e>
{
    800040da:	7159                	addi	sp,sp,-112
    800040dc:	f486                	sd	ra,104(sp)
    800040de:	f0a2                	sd	s0,96(sp)
    800040e0:	e8ca                	sd	s2,80(sp)
    800040e2:	e0d2                	sd	s4,64(sp)
    800040e4:	fc56                	sd	s5,56(sp)
    800040e6:	f85a                	sd	s6,48(sp)
    800040e8:	f45e                	sd	s7,40(sp)
    800040ea:	1880                	addi	s0,sp,112
    800040ec:	8aaa                	mv	s5,a0
    800040ee:	8bae                	mv	s7,a1
    800040f0:	8a32                	mv	s4,a2
    800040f2:	8936                	mv	s2,a3
    800040f4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040f6:	00e687bb          	addw	a5,a3,a4
    800040fa:	0ed7ee63          	bltu	a5,a3,800041f6 <writei+0x122>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040fe:	00043737          	lui	a4,0x43
    80004102:	0ef76c63          	bltu	a4,a5,800041fa <writei+0x126>
    80004106:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004108:	0c0b0d63          	beqz	s6,800041e2 <writei+0x10e>
    8000410c:	eca6                	sd	s1,88(sp)
    8000410e:	f062                	sd	s8,32(sp)
    80004110:	ec66                	sd	s9,24(sp)
    80004112:	e86a                	sd	s10,16(sp)
    80004114:	e46e                	sd	s11,8(sp)
    80004116:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004118:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000411c:	5c7d                	li	s8,-1
    8000411e:	a091                	j	80004162 <writei+0x8e>
    80004120:	020d1d93          	slli	s11,s10,0x20
    80004124:	020ddd93          	srli	s11,s11,0x20
    80004128:	05848513          	addi	a0,s1,88
    8000412c:	86ee                	mv	a3,s11
    8000412e:	8652                	mv	a2,s4
    80004130:	85de                	mv	a1,s7
    80004132:	953a                	add	a0,a0,a4
    80004134:	ffffe097          	auipc	ra,0xffffe
    80004138:	60c080e7          	jalr	1548(ra) # 80002740 <either_copyin>
    8000413c:	07850263          	beq	a0,s8,800041a0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004140:	8526                	mv	a0,s1
    80004142:	00000097          	auipc	ra,0x0
    80004146:	770080e7          	jalr	1904(ra) # 800048b2 <log_write>
    brelse(bp);
    8000414a:	8526                	mv	a0,s1
    8000414c:	fffff097          	auipc	ra,0xfffff
    80004150:	4bc080e7          	jalr	1212(ra) # 80003608 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004154:	013d09bb          	addw	s3,s10,s3
    80004158:	012d093b          	addw	s2,s10,s2
    8000415c:	9a6e                	add	s4,s4,s11
    8000415e:	0569f663          	bgeu	s3,s6,800041aa <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004162:	00a9559b          	srliw	a1,s2,0xa
    80004166:	8556                	mv	a0,s5
    80004168:	fffff097          	auipc	ra,0xfffff
    8000416c:	774080e7          	jalr	1908(ra) # 800038dc <bmap>
    80004170:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004174:	c99d                	beqz	a1,800041aa <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004176:	000aa503          	lw	a0,0(s5)
    8000417a:	fffff097          	auipc	ra,0xfffff
    8000417e:	35e080e7          	jalr	862(ra) # 800034d8 <bread>
    80004182:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004184:	3ff97713          	andi	a4,s2,1023
    80004188:	40ec87bb          	subw	a5,s9,a4
    8000418c:	413b06bb          	subw	a3,s6,s3
    80004190:	8d3e                	mv	s10,a5
    80004192:	2781                	sext.w	a5,a5
    80004194:	0006861b          	sext.w	a2,a3
    80004198:	f8f674e3          	bgeu	a2,a5,80004120 <writei+0x4c>
    8000419c:	8d36                	mv	s10,a3
    8000419e:	b749                	j	80004120 <writei+0x4c>
      brelse(bp);
    800041a0:	8526                	mv	a0,s1
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	466080e7          	jalr	1126(ra) # 80003608 <brelse>
  }

  if(off > ip->size)
    800041aa:	04caa783          	lw	a5,76(s5)
    800041ae:	0327fc63          	bgeu	a5,s2,800041e6 <writei+0x112>
    ip->size = off;
    800041b2:	052aa623          	sw	s2,76(s5)
    800041b6:	64e6                	ld	s1,88(sp)
    800041b8:	7c02                	ld	s8,32(sp)
    800041ba:	6ce2                	ld	s9,24(sp)
    800041bc:	6d42                	ld	s10,16(sp)
    800041be:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800041c0:	8556                	mv	a0,s5
    800041c2:	00000097          	auipc	ra,0x0
    800041c6:	a7e080e7          	jalr	-1410(ra) # 80003c40 <iupdate>

  return tot;
    800041ca:	0009851b          	sext.w	a0,s3
    800041ce:	69a6                	ld	s3,72(sp)
}
    800041d0:	70a6                	ld	ra,104(sp)
    800041d2:	7406                	ld	s0,96(sp)
    800041d4:	6946                	ld	s2,80(sp)
    800041d6:	6a06                	ld	s4,64(sp)
    800041d8:	7ae2                	ld	s5,56(sp)
    800041da:	7b42                	ld	s6,48(sp)
    800041dc:	7ba2                	ld	s7,40(sp)
    800041de:	6165                	addi	sp,sp,112
    800041e0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041e2:	89da                	mv	s3,s6
    800041e4:	bff1                	j	800041c0 <writei+0xec>
    800041e6:	64e6                	ld	s1,88(sp)
    800041e8:	7c02                	ld	s8,32(sp)
    800041ea:	6ce2                	ld	s9,24(sp)
    800041ec:	6d42                	ld	s10,16(sp)
    800041ee:	6da2                	ld	s11,8(sp)
    800041f0:	bfc1                	j	800041c0 <writei+0xec>
    return -1;
    800041f2:	557d                	li	a0,-1
}
    800041f4:	8082                	ret
    return -1;
    800041f6:	557d                	li	a0,-1
    800041f8:	bfe1                	j	800041d0 <writei+0xfc>
    return -1;
    800041fa:	557d                	li	a0,-1
    800041fc:	bfd1                	j	800041d0 <writei+0xfc>

00000000800041fe <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041fe:	1141                	addi	sp,sp,-16
    80004200:	e406                	sd	ra,8(sp)
    80004202:	e022                	sd	s0,0(sp)
    80004204:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004206:	4639                	li	a2,14
    80004208:	ffffd097          	auipc	ra,0xffffd
    8000420c:	bfc080e7          	jalr	-1028(ra) # 80000e04 <strncmp>
}
    80004210:	60a2                	ld	ra,8(sp)
    80004212:	6402                	ld	s0,0(sp)
    80004214:	0141                	addi	sp,sp,16
    80004216:	8082                	ret

0000000080004218 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004218:	7139                	addi	sp,sp,-64
    8000421a:	fc06                	sd	ra,56(sp)
    8000421c:	f822                	sd	s0,48(sp)
    8000421e:	f426                	sd	s1,40(sp)
    80004220:	f04a                	sd	s2,32(sp)
    80004222:	ec4e                	sd	s3,24(sp)
    80004224:	e852                	sd	s4,16(sp)
    80004226:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004228:	04451703          	lh	a4,68(a0)
    8000422c:	4785                	li	a5,1
    8000422e:	00f71a63          	bne	a4,a5,80004242 <dirlookup+0x2a>
    80004232:	892a                	mv	s2,a0
    80004234:	89ae                	mv	s3,a1
    80004236:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004238:	457c                	lw	a5,76(a0)
    8000423a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000423c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000423e:	e79d                	bnez	a5,8000426c <dirlookup+0x54>
    80004240:	a8a5                	j	800042b8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004242:	00004517          	auipc	a0,0x4
    80004246:	2ae50513          	addi	a0,a0,686 # 800084f0 <etext+0x4f0>
    8000424a:	ffffc097          	auipc	ra,0xffffc
    8000424e:	316080e7          	jalr	790(ra) # 80000560 <panic>
      panic("dirlookup read");
    80004252:	00004517          	auipc	a0,0x4
    80004256:	2b650513          	addi	a0,a0,694 # 80008508 <etext+0x508>
    8000425a:	ffffc097          	auipc	ra,0xffffc
    8000425e:	306080e7          	jalr	774(ra) # 80000560 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004262:	24c1                	addiw	s1,s1,16
    80004264:	04c92783          	lw	a5,76(s2)
    80004268:	04f4f763          	bgeu	s1,a5,800042b6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000426c:	4741                	li	a4,16
    8000426e:	86a6                	mv	a3,s1
    80004270:	fc040613          	addi	a2,s0,-64
    80004274:	4581                	li	a1,0
    80004276:	854a                	mv	a0,s2
    80004278:	00000097          	auipc	ra,0x0
    8000427c:	d4c080e7          	jalr	-692(ra) # 80003fc4 <readi>
    80004280:	47c1                	li	a5,16
    80004282:	fcf518e3          	bne	a0,a5,80004252 <dirlookup+0x3a>
    if(de.inum == 0)
    80004286:	fc045783          	lhu	a5,-64(s0)
    8000428a:	dfe1                	beqz	a5,80004262 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000428c:	fc240593          	addi	a1,s0,-62
    80004290:	854e                	mv	a0,s3
    80004292:	00000097          	auipc	ra,0x0
    80004296:	f6c080e7          	jalr	-148(ra) # 800041fe <namecmp>
    8000429a:	f561                	bnez	a0,80004262 <dirlookup+0x4a>
      if(poff)
    8000429c:	000a0463          	beqz	s4,800042a4 <dirlookup+0x8c>
        *poff = off;
    800042a0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800042a4:	fc045583          	lhu	a1,-64(s0)
    800042a8:	00092503          	lw	a0,0(s2)
    800042ac:	fffff097          	auipc	ra,0xfffff
    800042b0:	720080e7          	jalr	1824(ra) # 800039cc <iget>
    800042b4:	a011                	j	800042b8 <dirlookup+0xa0>
  return 0;
    800042b6:	4501                	li	a0,0
}
    800042b8:	70e2                	ld	ra,56(sp)
    800042ba:	7442                	ld	s0,48(sp)
    800042bc:	74a2                	ld	s1,40(sp)
    800042be:	7902                	ld	s2,32(sp)
    800042c0:	69e2                	ld	s3,24(sp)
    800042c2:	6a42                	ld	s4,16(sp)
    800042c4:	6121                	addi	sp,sp,64
    800042c6:	8082                	ret

00000000800042c8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042c8:	711d                	addi	sp,sp,-96
    800042ca:	ec86                	sd	ra,88(sp)
    800042cc:	e8a2                	sd	s0,80(sp)
    800042ce:	e4a6                	sd	s1,72(sp)
    800042d0:	e0ca                	sd	s2,64(sp)
    800042d2:	fc4e                	sd	s3,56(sp)
    800042d4:	f852                	sd	s4,48(sp)
    800042d6:	f456                	sd	s5,40(sp)
    800042d8:	f05a                	sd	s6,32(sp)
    800042da:	ec5e                	sd	s7,24(sp)
    800042dc:	e862                	sd	s8,16(sp)
    800042de:	e466                	sd	s9,8(sp)
    800042e0:	1080                	addi	s0,sp,96
    800042e2:	84aa                	mv	s1,a0
    800042e4:	8b2e                	mv	s6,a1
    800042e6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042e8:	00054703          	lbu	a4,0(a0)
    800042ec:	02f00793          	li	a5,47
    800042f0:	02f70263          	beq	a4,a5,80004314 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042f4:	ffffd097          	auipc	ra,0xffffd
    800042f8:	756080e7          	jalr	1878(ra) # 80001a4a <myproc>
    800042fc:	15053503          	ld	a0,336(a0)
    80004300:	00000097          	auipc	ra,0x0
    80004304:	9ce080e7          	jalr	-1586(ra) # 80003cce <idup>
    80004308:	8a2a                	mv	s4,a0
  while(*path == '/')
    8000430a:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000430e:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004310:	4b85                	li	s7,1
    80004312:	a875                	j	800043ce <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80004314:	4585                	li	a1,1
    80004316:	4505                	li	a0,1
    80004318:	fffff097          	auipc	ra,0xfffff
    8000431c:	6b4080e7          	jalr	1716(ra) # 800039cc <iget>
    80004320:	8a2a                	mv	s4,a0
    80004322:	b7e5                	j	8000430a <namex+0x42>
      iunlockput(ip);
    80004324:	8552                	mv	a0,s4
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	c4c080e7          	jalr	-948(ra) # 80003f72 <iunlockput>
      return 0;
    8000432e:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004330:	8552                	mv	a0,s4
    80004332:	60e6                	ld	ra,88(sp)
    80004334:	6446                	ld	s0,80(sp)
    80004336:	64a6                	ld	s1,72(sp)
    80004338:	6906                	ld	s2,64(sp)
    8000433a:	79e2                	ld	s3,56(sp)
    8000433c:	7a42                	ld	s4,48(sp)
    8000433e:	7aa2                	ld	s5,40(sp)
    80004340:	7b02                	ld	s6,32(sp)
    80004342:	6be2                	ld	s7,24(sp)
    80004344:	6c42                	ld	s8,16(sp)
    80004346:	6ca2                	ld	s9,8(sp)
    80004348:	6125                	addi	sp,sp,96
    8000434a:	8082                	ret
      iunlock(ip);
    8000434c:	8552                	mv	a0,s4
    8000434e:	00000097          	auipc	ra,0x0
    80004352:	a84080e7          	jalr	-1404(ra) # 80003dd2 <iunlock>
      return ip;
    80004356:	bfe9                	j	80004330 <namex+0x68>
      iunlockput(ip);
    80004358:	8552                	mv	a0,s4
    8000435a:	00000097          	auipc	ra,0x0
    8000435e:	c18080e7          	jalr	-1000(ra) # 80003f72 <iunlockput>
      return 0;
    80004362:	8a4e                	mv	s4,s3
    80004364:	b7f1                	j	80004330 <namex+0x68>
  len = path - s;
    80004366:	40998633          	sub	a2,s3,s1
    8000436a:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000436e:	099c5863          	bge	s8,s9,800043fe <namex+0x136>
    memmove(name, s, DIRSIZ);
    80004372:	4639                	li	a2,14
    80004374:	85a6                	mv	a1,s1
    80004376:	8556                	mv	a0,s5
    80004378:	ffffd097          	auipc	ra,0xffffd
    8000437c:	a18080e7          	jalr	-1512(ra) # 80000d90 <memmove>
    80004380:	84ce                	mv	s1,s3
  while(*path == '/')
    80004382:	0004c783          	lbu	a5,0(s1)
    80004386:	01279763          	bne	a5,s2,80004394 <namex+0xcc>
    path++;
    8000438a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000438c:	0004c783          	lbu	a5,0(s1)
    80004390:	ff278de3          	beq	a5,s2,8000438a <namex+0xc2>
    ilock(ip);
    80004394:	8552                	mv	a0,s4
    80004396:	00000097          	auipc	ra,0x0
    8000439a:	976080e7          	jalr	-1674(ra) # 80003d0c <ilock>
    if(ip->type != T_DIR){
    8000439e:	044a1783          	lh	a5,68(s4)
    800043a2:	f97791e3          	bne	a5,s7,80004324 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800043a6:	000b0563          	beqz	s6,800043b0 <namex+0xe8>
    800043aa:	0004c783          	lbu	a5,0(s1)
    800043ae:	dfd9                	beqz	a5,8000434c <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800043b0:	4601                	li	a2,0
    800043b2:	85d6                	mv	a1,s5
    800043b4:	8552                	mv	a0,s4
    800043b6:	00000097          	auipc	ra,0x0
    800043ba:	e62080e7          	jalr	-414(ra) # 80004218 <dirlookup>
    800043be:	89aa                	mv	s3,a0
    800043c0:	dd41                	beqz	a0,80004358 <namex+0x90>
    iunlockput(ip);
    800043c2:	8552                	mv	a0,s4
    800043c4:	00000097          	auipc	ra,0x0
    800043c8:	bae080e7          	jalr	-1106(ra) # 80003f72 <iunlockput>
    ip = next;
    800043cc:	8a4e                	mv	s4,s3
  while(*path == '/')
    800043ce:	0004c783          	lbu	a5,0(s1)
    800043d2:	01279763          	bne	a5,s2,800043e0 <namex+0x118>
    path++;
    800043d6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043d8:	0004c783          	lbu	a5,0(s1)
    800043dc:	ff278de3          	beq	a5,s2,800043d6 <namex+0x10e>
  if(*path == 0)
    800043e0:	cb9d                	beqz	a5,80004416 <namex+0x14e>
  while(*path != '/' && *path != 0)
    800043e2:	0004c783          	lbu	a5,0(s1)
    800043e6:	89a6                	mv	s3,s1
  len = path - s;
    800043e8:	4c81                	li	s9,0
    800043ea:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    800043ec:	01278963          	beq	a5,s2,800043fe <namex+0x136>
    800043f0:	dbbd                	beqz	a5,80004366 <namex+0x9e>
    path++;
    800043f2:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800043f4:	0009c783          	lbu	a5,0(s3)
    800043f8:	ff279ce3          	bne	a5,s2,800043f0 <namex+0x128>
    800043fc:	b7ad                	j	80004366 <namex+0x9e>
    memmove(name, s, len);
    800043fe:	2601                	sext.w	a2,a2
    80004400:	85a6                	mv	a1,s1
    80004402:	8556                	mv	a0,s5
    80004404:	ffffd097          	auipc	ra,0xffffd
    80004408:	98c080e7          	jalr	-1652(ra) # 80000d90 <memmove>
    name[len] = 0;
    8000440c:	9cd6                	add	s9,s9,s5
    8000440e:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004412:	84ce                	mv	s1,s3
    80004414:	b7bd                	j	80004382 <namex+0xba>
  if(nameiparent){
    80004416:	f00b0de3          	beqz	s6,80004330 <namex+0x68>
    iput(ip);
    8000441a:	8552                	mv	a0,s4
    8000441c:	00000097          	auipc	ra,0x0
    80004420:	aae080e7          	jalr	-1362(ra) # 80003eca <iput>
    return 0;
    80004424:	4a01                	li	s4,0
    80004426:	b729                	j	80004330 <namex+0x68>

0000000080004428 <dirlink>:
{
    80004428:	7139                	addi	sp,sp,-64
    8000442a:	fc06                	sd	ra,56(sp)
    8000442c:	f822                	sd	s0,48(sp)
    8000442e:	f04a                	sd	s2,32(sp)
    80004430:	ec4e                	sd	s3,24(sp)
    80004432:	e852                	sd	s4,16(sp)
    80004434:	0080                	addi	s0,sp,64
    80004436:	892a                	mv	s2,a0
    80004438:	8a2e                	mv	s4,a1
    8000443a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000443c:	4601                	li	a2,0
    8000443e:	00000097          	auipc	ra,0x0
    80004442:	dda080e7          	jalr	-550(ra) # 80004218 <dirlookup>
    80004446:	ed25                	bnez	a0,800044be <dirlink+0x96>
    80004448:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000444a:	04c92483          	lw	s1,76(s2)
    8000444e:	c49d                	beqz	s1,8000447c <dirlink+0x54>
    80004450:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004452:	4741                	li	a4,16
    80004454:	86a6                	mv	a3,s1
    80004456:	fc040613          	addi	a2,s0,-64
    8000445a:	4581                	li	a1,0
    8000445c:	854a                	mv	a0,s2
    8000445e:	00000097          	auipc	ra,0x0
    80004462:	b66080e7          	jalr	-1178(ra) # 80003fc4 <readi>
    80004466:	47c1                	li	a5,16
    80004468:	06f51163          	bne	a0,a5,800044ca <dirlink+0xa2>
    if(de.inum == 0)
    8000446c:	fc045783          	lhu	a5,-64(s0)
    80004470:	c791                	beqz	a5,8000447c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004472:	24c1                	addiw	s1,s1,16
    80004474:	04c92783          	lw	a5,76(s2)
    80004478:	fcf4ede3          	bltu	s1,a5,80004452 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000447c:	4639                	li	a2,14
    8000447e:	85d2                	mv	a1,s4
    80004480:	fc240513          	addi	a0,s0,-62
    80004484:	ffffd097          	auipc	ra,0xffffd
    80004488:	9b6080e7          	jalr	-1610(ra) # 80000e3a <strncpy>
  de.inum = inum;
    8000448c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004490:	4741                	li	a4,16
    80004492:	86a6                	mv	a3,s1
    80004494:	fc040613          	addi	a2,s0,-64
    80004498:	4581                	li	a1,0
    8000449a:	854a                	mv	a0,s2
    8000449c:	00000097          	auipc	ra,0x0
    800044a0:	c38080e7          	jalr	-968(ra) # 800040d4 <writei>
    800044a4:	1541                	addi	a0,a0,-16
    800044a6:	00a03533          	snez	a0,a0
    800044aa:	40a00533          	neg	a0,a0
    800044ae:	74a2                	ld	s1,40(sp)
}
    800044b0:	70e2                	ld	ra,56(sp)
    800044b2:	7442                	ld	s0,48(sp)
    800044b4:	7902                	ld	s2,32(sp)
    800044b6:	69e2                	ld	s3,24(sp)
    800044b8:	6a42                	ld	s4,16(sp)
    800044ba:	6121                	addi	sp,sp,64
    800044bc:	8082                	ret
    iput(ip);
    800044be:	00000097          	auipc	ra,0x0
    800044c2:	a0c080e7          	jalr	-1524(ra) # 80003eca <iput>
    return -1;
    800044c6:	557d                	li	a0,-1
    800044c8:	b7e5                	j	800044b0 <dirlink+0x88>
      panic("dirlink read");
    800044ca:	00004517          	auipc	a0,0x4
    800044ce:	04e50513          	addi	a0,a0,78 # 80008518 <etext+0x518>
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	08e080e7          	jalr	142(ra) # 80000560 <panic>

00000000800044da <namei>:

struct inode*
namei(char *path)
{
    800044da:	1101                	addi	sp,sp,-32
    800044dc:	ec06                	sd	ra,24(sp)
    800044de:	e822                	sd	s0,16(sp)
    800044e0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044e2:	fe040613          	addi	a2,s0,-32
    800044e6:	4581                	li	a1,0
    800044e8:	00000097          	auipc	ra,0x0
    800044ec:	de0080e7          	jalr	-544(ra) # 800042c8 <namex>
}
    800044f0:	60e2                	ld	ra,24(sp)
    800044f2:	6442                	ld	s0,16(sp)
    800044f4:	6105                	addi	sp,sp,32
    800044f6:	8082                	ret

00000000800044f8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044f8:	1141                	addi	sp,sp,-16
    800044fa:	e406                	sd	ra,8(sp)
    800044fc:	e022                	sd	s0,0(sp)
    800044fe:	0800                	addi	s0,sp,16
    80004500:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004502:	4585                	li	a1,1
    80004504:	00000097          	auipc	ra,0x0
    80004508:	dc4080e7          	jalr	-572(ra) # 800042c8 <namex>
}
    8000450c:	60a2                	ld	ra,8(sp)
    8000450e:	6402                	ld	s0,0(sp)
    80004510:	0141                	addi	sp,sp,16
    80004512:	8082                	ret

0000000080004514 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004514:	1101                	addi	sp,sp,-32
    80004516:	ec06                	sd	ra,24(sp)
    80004518:	e822                	sd	s0,16(sp)
    8000451a:	e426                	sd	s1,8(sp)
    8000451c:	e04a                	sd	s2,0(sp)
    8000451e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004520:	00022917          	auipc	s2,0x22
    80004524:	ed090913          	addi	s2,s2,-304 # 800263f0 <log>
    80004528:	01892583          	lw	a1,24(s2)
    8000452c:	02892503          	lw	a0,40(s2)
    80004530:	fffff097          	auipc	ra,0xfffff
    80004534:	fa8080e7          	jalr	-88(ra) # 800034d8 <bread>
    80004538:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000453a:	02c92603          	lw	a2,44(s2)
    8000453e:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004540:	00c05f63          	blez	a2,8000455e <write_head+0x4a>
    80004544:	00022717          	auipc	a4,0x22
    80004548:	edc70713          	addi	a4,a4,-292 # 80026420 <log+0x30>
    8000454c:	87aa                	mv	a5,a0
    8000454e:	060a                	slli	a2,a2,0x2
    80004550:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004552:	4314                	lw	a3,0(a4)
    80004554:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004556:	0711                	addi	a4,a4,4
    80004558:	0791                	addi	a5,a5,4
    8000455a:	fec79ce3          	bne	a5,a2,80004552 <write_head+0x3e>
  }
  bwrite(buf);
    8000455e:	8526                	mv	a0,s1
    80004560:	fffff097          	auipc	ra,0xfffff
    80004564:	06a080e7          	jalr	106(ra) # 800035ca <bwrite>
  brelse(buf);
    80004568:	8526                	mv	a0,s1
    8000456a:	fffff097          	auipc	ra,0xfffff
    8000456e:	09e080e7          	jalr	158(ra) # 80003608 <brelse>
}
    80004572:	60e2                	ld	ra,24(sp)
    80004574:	6442                	ld	s0,16(sp)
    80004576:	64a2                	ld	s1,8(sp)
    80004578:	6902                	ld	s2,0(sp)
    8000457a:	6105                	addi	sp,sp,32
    8000457c:	8082                	ret

000000008000457e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000457e:	00022797          	auipc	a5,0x22
    80004582:	e9e7a783          	lw	a5,-354(a5) # 8002641c <log+0x2c>
    80004586:	0af05d63          	blez	a5,80004640 <install_trans+0xc2>
{
    8000458a:	7139                	addi	sp,sp,-64
    8000458c:	fc06                	sd	ra,56(sp)
    8000458e:	f822                	sd	s0,48(sp)
    80004590:	f426                	sd	s1,40(sp)
    80004592:	f04a                	sd	s2,32(sp)
    80004594:	ec4e                	sd	s3,24(sp)
    80004596:	e852                	sd	s4,16(sp)
    80004598:	e456                	sd	s5,8(sp)
    8000459a:	e05a                	sd	s6,0(sp)
    8000459c:	0080                	addi	s0,sp,64
    8000459e:	8b2a                	mv	s6,a0
    800045a0:	00022a97          	auipc	s5,0x22
    800045a4:	e80a8a93          	addi	s5,s5,-384 # 80026420 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045a8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045aa:	00022997          	auipc	s3,0x22
    800045ae:	e4698993          	addi	s3,s3,-442 # 800263f0 <log>
    800045b2:	a00d                	j	800045d4 <install_trans+0x56>
    brelse(lbuf);
    800045b4:	854a                	mv	a0,s2
    800045b6:	fffff097          	auipc	ra,0xfffff
    800045ba:	052080e7          	jalr	82(ra) # 80003608 <brelse>
    brelse(dbuf);
    800045be:	8526                	mv	a0,s1
    800045c0:	fffff097          	auipc	ra,0xfffff
    800045c4:	048080e7          	jalr	72(ra) # 80003608 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045c8:	2a05                	addiw	s4,s4,1
    800045ca:	0a91                	addi	s5,s5,4
    800045cc:	02c9a783          	lw	a5,44(s3)
    800045d0:	04fa5e63          	bge	s4,a5,8000462c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045d4:	0189a583          	lw	a1,24(s3)
    800045d8:	014585bb          	addw	a1,a1,s4
    800045dc:	2585                	addiw	a1,a1,1
    800045de:	0289a503          	lw	a0,40(s3)
    800045e2:	fffff097          	auipc	ra,0xfffff
    800045e6:	ef6080e7          	jalr	-266(ra) # 800034d8 <bread>
    800045ea:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045ec:	000aa583          	lw	a1,0(s5)
    800045f0:	0289a503          	lw	a0,40(s3)
    800045f4:	fffff097          	auipc	ra,0xfffff
    800045f8:	ee4080e7          	jalr	-284(ra) # 800034d8 <bread>
    800045fc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800045fe:	40000613          	li	a2,1024
    80004602:	05890593          	addi	a1,s2,88
    80004606:	05850513          	addi	a0,a0,88
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	786080e7          	jalr	1926(ra) # 80000d90 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004612:	8526                	mv	a0,s1
    80004614:	fffff097          	auipc	ra,0xfffff
    80004618:	fb6080e7          	jalr	-74(ra) # 800035ca <bwrite>
    if(recovering == 0)
    8000461c:	f80b1ce3          	bnez	s6,800045b4 <install_trans+0x36>
      bunpin(dbuf);
    80004620:	8526                	mv	a0,s1
    80004622:	fffff097          	auipc	ra,0xfffff
    80004626:	0be080e7          	jalr	190(ra) # 800036e0 <bunpin>
    8000462a:	b769                	j	800045b4 <install_trans+0x36>
}
    8000462c:	70e2                	ld	ra,56(sp)
    8000462e:	7442                	ld	s0,48(sp)
    80004630:	74a2                	ld	s1,40(sp)
    80004632:	7902                	ld	s2,32(sp)
    80004634:	69e2                	ld	s3,24(sp)
    80004636:	6a42                	ld	s4,16(sp)
    80004638:	6aa2                	ld	s5,8(sp)
    8000463a:	6b02                	ld	s6,0(sp)
    8000463c:	6121                	addi	sp,sp,64
    8000463e:	8082                	ret
    80004640:	8082                	ret

0000000080004642 <initlog>:
{
    80004642:	7179                	addi	sp,sp,-48
    80004644:	f406                	sd	ra,40(sp)
    80004646:	f022                	sd	s0,32(sp)
    80004648:	ec26                	sd	s1,24(sp)
    8000464a:	e84a                	sd	s2,16(sp)
    8000464c:	e44e                	sd	s3,8(sp)
    8000464e:	1800                	addi	s0,sp,48
    80004650:	892a                	mv	s2,a0
    80004652:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004654:	00022497          	auipc	s1,0x22
    80004658:	d9c48493          	addi	s1,s1,-612 # 800263f0 <log>
    8000465c:	00004597          	auipc	a1,0x4
    80004660:	ecc58593          	addi	a1,a1,-308 # 80008528 <etext+0x528>
    80004664:	8526                	mv	a0,s1
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	542080e7          	jalr	1346(ra) # 80000ba8 <initlock>
  log.start = sb->logstart;
    8000466e:	0149a583          	lw	a1,20(s3)
    80004672:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004674:	0109a783          	lw	a5,16(s3)
    80004678:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000467a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000467e:	854a                	mv	a0,s2
    80004680:	fffff097          	auipc	ra,0xfffff
    80004684:	e58080e7          	jalr	-424(ra) # 800034d8 <bread>
  log.lh.n = lh->n;
    80004688:	4d30                	lw	a2,88(a0)
    8000468a:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000468c:	00c05f63          	blez	a2,800046aa <initlog+0x68>
    80004690:	87aa                	mv	a5,a0
    80004692:	00022717          	auipc	a4,0x22
    80004696:	d8e70713          	addi	a4,a4,-626 # 80026420 <log+0x30>
    8000469a:	060a                	slli	a2,a2,0x2
    8000469c:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    8000469e:	4ff4                	lw	a3,92(a5)
    800046a0:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800046a2:	0791                	addi	a5,a5,4
    800046a4:	0711                	addi	a4,a4,4
    800046a6:	fec79ce3          	bne	a5,a2,8000469e <initlog+0x5c>
  brelse(buf);
    800046aa:	fffff097          	auipc	ra,0xfffff
    800046ae:	f5e080e7          	jalr	-162(ra) # 80003608 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046b2:	4505                	li	a0,1
    800046b4:	00000097          	auipc	ra,0x0
    800046b8:	eca080e7          	jalr	-310(ra) # 8000457e <install_trans>
  log.lh.n = 0;
    800046bc:	00022797          	auipc	a5,0x22
    800046c0:	d607a023          	sw	zero,-672(a5) # 8002641c <log+0x2c>
  write_head(); // clear the log
    800046c4:	00000097          	auipc	ra,0x0
    800046c8:	e50080e7          	jalr	-432(ra) # 80004514 <write_head>
}
    800046cc:	70a2                	ld	ra,40(sp)
    800046ce:	7402                	ld	s0,32(sp)
    800046d0:	64e2                	ld	s1,24(sp)
    800046d2:	6942                	ld	s2,16(sp)
    800046d4:	69a2                	ld	s3,8(sp)
    800046d6:	6145                	addi	sp,sp,48
    800046d8:	8082                	ret

00000000800046da <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046da:	1101                	addi	sp,sp,-32
    800046dc:	ec06                	sd	ra,24(sp)
    800046de:	e822                	sd	s0,16(sp)
    800046e0:	e426                	sd	s1,8(sp)
    800046e2:	e04a                	sd	s2,0(sp)
    800046e4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046e6:	00022517          	auipc	a0,0x22
    800046ea:	d0a50513          	addi	a0,a0,-758 # 800263f0 <log>
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	54a080e7          	jalr	1354(ra) # 80000c38 <acquire>
  while(1){
    if(log.committing){
    800046f6:	00022497          	auipc	s1,0x22
    800046fa:	cfa48493          	addi	s1,s1,-774 # 800263f0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046fe:	4979                	li	s2,30
    80004700:	a039                	j	8000470e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004702:	85a6                	mv	a1,s1
    80004704:	8526                	mv	a0,s1
    80004706:	ffffe097          	auipc	ra,0xffffe
    8000470a:	ba8080e7          	jalr	-1112(ra) # 800022ae <sleep>
    if(log.committing){
    8000470e:	50dc                	lw	a5,36(s1)
    80004710:	fbed                	bnez	a5,80004702 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004712:	5098                	lw	a4,32(s1)
    80004714:	2705                	addiw	a4,a4,1
    80004716:	0027179b          	slliw	a5,a4,0x2
    8000471a:	9fb9                	addw	a5,a5,a4
    8000471c:	0017979b          	slliw	a5,a5,0x1
    80004720:	54d4                	lw	a3,44(s1)
    80004722:	9fb5                	addw	a5,a5,a3
    80004724:	00f95963          	bge	s2,a5,80004736 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004728:	85a6                	mv	a1,s1
    8000472a:	8526                	mv	a0,s1
    8000472c:	ffffe097          	auipc	ra,0xffffe
    80004730:	b82080e7          	jalr	-1150(ra) # 800022ae <sleep>
    80004734:	bfe9                	j	8000470e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004736:	00022517          	auipc	a0,0x22
    8000473a:	cba50513          	addi	a0,a0,-838 # 800263f0 <log>
    8000473e:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004740:	ffffc097          	auipc	ra,0xffffc
    80004744:	5ac080e7          	jalr	1452(ra) # 80000cec <release>
      break;
    }
  }
}
    80004748:	60e2                	ld	ra,24(sp)
    8000474a:	6442                	ld	s0,16(sp)
    8000474c:	64a2                	ld	s1,8(sp)
    8000474e:	6902                	ld	s2,0(sp)
    80004750:	6105                	addi	sp,sp,32
    80004752:	8082                	ret

0000000080004754 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004754:	7139                	addi	sp,sp,-64
    80004756:	fc06                	sd	ra,56(sp)
    80004758:	f822                	sd	s0,48(sp)
    8000475a:	f426                	sd	s1,40(sp)
    8000475c:	f04a                	sd	s2,32(sp)
    8000475e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004760:	00022497          	auipc	s1,0x22
    80004764:	c9048493          	addi	s1,s1,-880 # 800263f0 <log>
    80004768:	8526                	mv	a0,s1
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	4ce080e7          	jalr	1230(ra) # 80000c38 <acquire>
  log.outstanding -= 1;
    80004772:	509c                	lw	a5,32(s1)
    80004774:	37fd                	addiw	a5,a5,-1
    80004776:	0007891b          	sext.w	s2,a5
    8000477a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000477c:	50dc                	lw	a5,36(s1)
    8000477e:	e7b9                	bnez	a5,800047cc <end_op+0x78>
    panic("log.committing");
  if(log.outstanding == 0){
    80004780:	06091163          	bnez	s2,800047e2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004784:	00022497          	auipc	s1,0x22
    80004788:	c6c48493          	addi	s1,s1,-916 # 800263f0 <log>
    8000478c:	4785                	li	a5,1
    8000478e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004790:	8526                	mv	a0,s1
    80004792:	ffffc097          	auipc	ra,0xffffc
    80004796:	55a080e7          	jalr	1370(ra) # 80000cec <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000479a:	54dc                	lw	a5,44(s1)
    8000479c:	06f04763          	bgtz	a5,8000480a <end_op+0xb6>
    acquire(&log.lock);
    800047a0:	00022497          	auipc	s1,0x22
    800047a4:	c5048493          	addi	s1,s1,-944 # 800263f0 <log>
    800047a8:	8526                	mv	a0,s1
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	48e080e7          	jalr	1166(ra) # 80000c38 <acquire>
    log.committing = 0;
    800047b2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047b6:	8526                	mv	a0,s1
    800047b8:	ffffe097          	auipc	ra,0xffffe
    800047bc:	b5a080e7          	jalr	-1190(ra) # 80002312 <wakeup>
    release(&log.lock);
    800047c0:	8526                	mv	a0,s1
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	52a080e7          	jalr	1322(ra) # 80000cec <release>
}
    800047ca:	a815                	j	800047fe <end_op+0xaa>
    800047cc:	ec4e                	sd	s3,24(sp)
    800047ce:	e852                	sd	s4,16(sp)
    800047d0:	e456                	sd	s5,8(sp)
    panic("log.committing");
    800047d2:	00004517          	auipc	a0,0x4
    800047d6:	d5e50513          	addi	a0,a0,-674 # 80008530 <etext+0x530>
    800047da:	ffffc097          	auipc	ra,0xffffc
    800047de:	d86080e7          	jalr	-634(ra) # 80000560 <panic>
    wakeup(&log);
    800047e2:	00022497          	auipc	s1,0x22
    800047e6:	c0e48493          	addi	s1,s1,-1010 # 800263f0 <log>
    800047ea:	8526                	mv	a0,s1
    800047ec:	ffffe097          	auipc	ra,0xffffe
    800047f0:	b26080e7          	jalr	-1242(ra) # 80002312 <wakeup>
  release(&log.lock);
    800047f4:	8526                	mv	a0,s1
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	4f6080e7          	jalr	1270(ra) # 80000cec <release>
}
    800047fe:	70e2                	ld	ra,56(sp)
    80004800:	7442                	ld	s0,48(sp)
    80004802:	74a2                	ld	s1,40(sp)
    80004804:	7902                	ld	s2,32(sp)
    80004806:	6121                	addi	sp,sp,64
    80004808:	8082                	ret
    8000480a:	ec4e                	sd	s3,24(sp)
    8000480c:	e852                	sd	s4,16(sp)
    8000480e:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    80004810:	00022a97          	auipc	s5,0x22
    80004814:	c10a8a93          	addi	s5,s5,-1008 # 80026420 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004818:	00022a17          	auipc	s4,0x22
    8000481c:	bd8a0a13          	addi	s4,s4,-1064 # 800263f0 <log>
    80004820:	018a2583          	lw	a1,24(s4)
    80004824:	012585bb          	addw	a1,a1,s2
    80004828:	2585                	addiw	a1,a1,1
    8000482a:	028a2503          	lw	a0,40(s4)
    8000482e:	fffff097          	auipc	ra,0xfffff
    80004832:	caa080e7          	jalr	-854(ra) # 800034d8 <bread>
    80004836:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004838:	000aa583          	lw	a1,0(s5)
    8000483c:	028a2503          	lw	a0,40(s4)
    80004840:	fffff097          	auipc	ra,0xfffff
    80004844:	c98080e7          	jalr	-872(ra) # 800034d8 <bread>
    80004848:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000484a:	40000613          	li	a2,1024
    8000484e:	05850593          	addi	a1,a0,88
    80004852:	05848513          	addi	a0,s1,88
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	53a080e7          	jalr	1338(ra) # 80000d90 <memmove>
    bwrite(to);  // write the log
    8000485e:	8526                	mv	a0,s1
    80004860:	fffff097          	auipc	ra,0xfffff
    80004864:	d6a080e7          	jalr	-662(ra) # 800035ca <bwrite>
    brelse(from);
    80004868:	854e                	mv	a0,s3
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	d9e080e7          	jalr	-610(ra) # 80003608 <brelse>
    brelse(to);
    80004872:	8526                	mv	a0,s1
    80004874:	fffff097          	auipc	ra,0xfffff
    80004878:	d94080e7          	jalr	-620(ra) # 80003608 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000487c:	2905                	addiw	s2,s2,1
    8000487e:	0a91                	addi	s5,s5,4
    80004880:	02ca2783          	lw	a5,44(s4)
    80004884:	f8f94ee3          	blt	s2,a5,80004820 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004888:	00000097          	auipc	ra,0x0
    8000488c:	c8c080e7          	jalr	-884(ra) # 80004514 <write_head>
    install_trans(0); // Now install writes to home locations
    80004890:	4501                	li	a0,0
    80004892:	00000097          	auipc	ra,0x0
    80004896:	cec080e7          	jalr	-788(ra) # 8000457e <install_trans>
    log.lh.n = 0;
    8000489a:	00022797          	auipc	a5,0x22
    8000489e:	b807a123          	sw	zero,-1150(a5) # 8002641c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048a2:	00000097          	auipc	ra,0x0
    800048a6:	c72080e7          	jalr	-910(ra) # 80004514 <write_head>
    800048aa:	69e2                	ld	s3,24(sp)
    800048ac:	6a42                	ld	s4,16(sp)
    800048ae:	6aa2                	ld	s5,8(sp)
    800048b0:	bdc5                	j	800047a0 <end_op+0x4c>

00000000800048b2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048b2:	1101                	addi	sp,sp,-32
    800048b4:	ec06                	sd	ra,24(sp)
    800048b6:	e822                	sd	s0,16(sp)
    800048b8:	e426                	sd	s1,8(sp)
    800048ba:	e04a                	sd	s2,0(sp)
    800048bc:	1000                	addi	s0,sp,32
    800048be:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048c0:	00022917          	auipc	s2,0x22
    800048c4:	b3090913          	addi	s2,s2,-1232 # 800263f0 <log>
    800048c8:	854a                	mv	a0,s2
    800048ca:	ffffc097          	auipc	ra,0xffffc
    800048ce:	36e080e7          	jalr	878(ra) # 80000c38 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048d2:	02c92603          	lw	a2,44(s2)
    800048d6:	47f5                	li	a5,29
    800048d8:	06c7c563          	blt	a5,a2,80004942 <log_write+0x90>
    800048dc:	00022797          	auipc	a5,0x22
    800048e0:	b307a783          	lw	a5,-1232(a5) # 8002640c <log+0x1c>
    800048e4:	37fd                	addiw	a5,a5,-1
    800048e6:	04f65e63          	bge	a2,a5,80004942 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048ea:	00022797          	auipc	a5,0x22
    800048ee:	b267a783          	lw	a5,-1242(a5) # 80026410 <log+0x20>
    800048f2:	06f05063          	blez	a5,80004952 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048f6:	4781                	li	a5,0
    800048f8:	06c05563          	blez	a2,80004962 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048fc:	44cc                	lw	a1,12(s1)
    800048fe:	00022717          	auipc	a4,0x22
    80004902:	b2270713          	addi	a4,a4,-1246 # 80026420 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004906:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004908:	4314                	lw	a3,0(a4)
    8000490a:	04b68c63          	beq	a3,a1,80004962 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000490e:	2785                	addiw	a5,a5,1
    80004910:	0711                	addi	a4,a4,4
    80004912:	fef61be3          	bne	a2,a5,80004908 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004916:	0621                	addi	a2,a2,8
    80004918:	060a                	slli	a2,a2,0x2
    8000491a:	00022797          	auipc	a5,0x22
    8000491e:	ad678793          	addi	a5,a5,-1322 # 800263f0 <log>
    80004922:	97b2                	add	a5,a5,a2
    80004924:	44d8                	lw	a4,12(s1)
    80004926:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004928:	8526                	mv	a0,s1
    8000492a:	fffff097          	auipc	ra,0xfffff
    8000492e:	d7a080e7          	jalr	-646(ra) # 800036a4 <bpin>
    log.lh.n++;
    80004932:	00022717          	auipc	a4,0x22
    80004936:	abe70713          	addi	a4,a4,-1346 # 800263f0 <log>
    8000493a:	575c                	lw	a5,44(a4)
    8000493c:	2785                	addiw	a5,a5,1
    8000493e:	d75c                	sw	a5,44(a4)
    80004940:	a82d                	j	8000497a <log_write+0xc8>
    panic("too big a transaction");
    80004942:	00004517          	auipc	a0,0x4
    80004946:	bfe50513          	addi	a0,a0,-1026 # 80008540 <etext+0x540>
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	c16080e7          	jalr	-1002(ra) # 80000560 <panic>
    panic("log_write outside of trans");
    80004952:	00004517          	auipc	a0,0x4
    80004956:	c0650513          	addi	a0,a0,-1018 # 80008558 <etext+0x558>
    8000495a:	ffffc097          	auipc	ra,0xffffc
    8000495e:	c06080e7          	jalr	-1018(ra) # 80000560 <panic>
  log.lh.block[i] = b->blockno;
    80004962:	00878693          	addi	a3,a5,8
    80004966:	068a                	slli	a3,a3,0x2
    80004968:	00022717          	auipc	a4,0x22
    8000496c:	a8870713          	addi	a4,a4,-1400 # 800263f0 <log>
    80004970:	9736                	add	a4,a4,a3
    80004972:	44d4                	lw	a3,12(s1)
    80004974:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004976:	faf609e3          	beq	a2,a5,80004928 <log_write+0x76>
  }
  release(&log.lock);
    8000497a:	00022517          	auipc	a0,0x22
    8000497e:	a7650513          	addi	a0,a0,-1418 # 800263f0 <log>
    80004982:	ffffc097          	auipc	ra,0xffffc
    80004986:	36a080e7          	jalr	874(ra) # 80000cec <release>
}
    8000498a:	60e2                	ld	ra,24(sp)
    8000498c:	6442                	ld	s0,16(sp)
    8000498e:	64a2                	ld	s1,8(sp)
    80004990:	6902                	ld	s2,0(sp)
    80004992:	6105                	addi	sp,sp,32
    80004994:	8082                	ret

0000000080004996 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004996:	1101                	addi	sp,sp,-32
    80004998:	ec06                	sd	ra,24(sp)
    8000499a:	e822                	sd	s0,16(sp)
    8000499c:	e426                	sd	s1,8(sp)
    8000499e:	e04a                	sd	s2,0(sp)
    800049a0:	1000                	addi	s0,sp,32
    800049a2:	84aa                	mv	s1,a0
    800049a4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049a6:	00004597          	auipc	a1,0x4
    800049aa:	bd258593          	addi	a1,a1,-1070 # 80008578 <etext+0x578>
    800049ae:	0521                	addi	a0,a0,8
    800049b0:	ffffc097          	auipc	ra,0xffffc
    800049b4:	1f8080e7          	jalr	504(ra) # 80000ba8 <initlock>
  lk->name = name;
    800049b8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049bc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049c0:	0204a423          	sw	zero,40(s1)
}
    800049c4:	60e2                	ld	ra,24(sp)
    800049c6:	6442                	ld	s0,16(sp)
    800049c8:	64a2                	ld	s1,8(sp)
    800049ca:	6902                	ld	s2,0(sp)
    800049cc:	6105                	addi	sp,sp,32
    800049ce:	8082                	ret

00000000800049d0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049d0:	1101                	addi	sp,sp,-32
    800049d2:	ec06                	sd	ra,24(sp)
    800049d4:	e822                	sd	s0,16(sp)
    800049d6:	e426                	sd	s1,8(sp)
    800049d8:	e04a                	sd	s2,0(sp)
    800049da:	1000                	addi	s0,sp,32
    800049dc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049de:	00850913          	addi	s2,a0,8
    800049e2:	854a                	mv	a0,s2
    800049e4:	ffffc097          	auipc	ra,0xffffc
    800049e8:	254080e7          	jalr	596(ra) # 80000c38 <acquire>
  while (lk->locked) {
    800049ec:	409c                	lw	a5,0(s1)
    800049ee:	cb89                	beqz	a5,80004a00 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049f0:	85ca                	mv	a1,s2
    800049f2:	8526                	mv	a0,s1
    800049f4:	ffffe097          	auipc	ra,0xffffe
    800049f8:	8ba080e7          	jalr	-1862(ra) # 800022ae <sleep>
  while (lk->locked) {
    800049fc:	409c                	lw	a5,0(s1)
    800049fe:	fbed                	bnez	a5,800049f0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a00:	4785                	li	a5,1
    80004a02:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a04:	ffffd097          	auipc	ra,0xffffd
    80004a08:	046080e7          	jalr	70(ra) # 80001a4a <myproc>
    80004a0c:	591c                	lw	a5,48(a0)
    80004a0e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a10:	854a                	mv	a0,s2
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	2da080e7          	jalr	730(ra) # 80000cec <release>
}
    80004a1a:	60e2                	ld	ra,24(sp)
    80004a1c:	6442                	ld	s0,16(sp)
    80004a1e:	64a2                	ld	s1,8(sp)
    80004a20:	6902                	ld	s2,0(sp)
    80004a22:	6105                	addi	sp,sp,32
    80004a24:	8082                	ret

0000000080004a26 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a26:	1101                	addi	sp,sp,-32
    80004a28:	ec06                	sd	ra,24(sp)
    80004a2a:	e822                	sd	s0,16(sp)
    80004a2c:	e426                	sd	s1,8(sp)
    80004a2e:	e04a                	sd	s2,0(sp)
    80004a30:	1000                	addi	s0,sp,32
    80004a32:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a34:	00850913          	addi	s2,a0,8
    80004a38:	854a                	mv	a0,s2
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	1fe080e7          	jalr	510(ra) # 80000c38 <acquire>
  lk->locked = 0;
    80004a42:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a46:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a4a:	8526                	mv	a0,s1
    80004a4c:	ffffe097          	auipc	ra,0xffffe
    80004a50:	8c6080e7          	jalr	-1850(ra) # 80002312 <wakeup>
  release(&lk->lk);
    80004a54:	854a                	mv	a0,s2
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	296080e7          	jalr	662(ra) # 80000cec <release>
}
    80004a5e:	60e2                	ld	ra,24(sp)
    80004a60:	6442                	ld	s0,16(sp)
    80004a62:	64a2                	ld	s1,8(sp)
    80004a64:	6902                	ld	s2,0(sp)
    80004a66:	6105                	addi	sp,sp,32
    80004a68:	8082                	ret

0000000080004a6a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a6a:	7179                	addi	sp,sp,-48
    80004a6c:	f406                	sd	ra,40(sp)
    80004a6e:	f022                	sd	s0,32(sp)
    80004a70:	ec26                	sd	s1,24(sp)
    80004a72:	e84a                	sd	s2,16(sp)
    80004a74:	1800                	addi	s0,sp,48
    80004a76:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a78:	00850913          	addi	s2,a0,8
    80004a7c:	854a                	mv	a0,s2
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	1ba080e7          	jalr	442(ra) # 80000c38 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a86:	409c                	lw	a5,0(s1)
    80004a88:	ef91                	bnez	a5,80004aa4 <holdingsleep+0x3a>
    80004a8a:	4481                	li	s1,0
  release(&lk->lk);
    80004a8c:	854a                	mv	a0,s2
    80004a8e:	ffffc097          	auipc	ra,0xffffc
    80004a92:	25e080e7          	jalr	606(ra) # 80000cec <release>
  return r;
}
    80004a96:	8526                	mv	a0,s1
    80004a98:	70a2                	ld	ra,40(sp)
    80004a9a:	7402                	ld	s0,32(sp)
    80004a9c:	64e2                	ld	s1,24(sp)
    80004a9e:	6942                	ld	s2,16(sp)
    80004aa0:	6145                	addi	sp,sp,48
    80004aa2:	8082                	ret
    80004aa4:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    80004aa6:	0284a983          	lw	s3,40(s1)
    80004aaa:	ffffd097          	auipc	ra,0xffffd
    80004aae:	fa0080e7          	jalr	-96(ra) # 80001a4a <myproc>
    80004ab2:	5904                	lw	s1,48(a0)
    80004ab4:	413484b3          	sub	s1,s1,s3
    80004ab8:	0014b493          	seqz	s1,s1
    80004abc:	69a2                	ld	s3,8(sp)
    80004abe:	b7f9                	j	80004a8c <holdingsleep+0x22>

0000000080004ac0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ac0:	1141                	addi	sp,sp,-16
    80004ac2:	e406                	sd	ra,8(sp)
    80004ac4:	e022                	sd	s0,0(sp)
    80004ac6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ac8:	00004597          	auipc	a1,0x4
    80004acc:	ac058593          	addi	a1,a1,-1344 # 80008588 <etext+0x588>
    80004ad0:	00022517          	auipc	a0,0x22
    80004ad4:	a6850513          	addi	a0,a0,-1432 # 80026538 <ftable>
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	0d0080e7          	jalr	208(ra) # 80000ba8 <initlock>
}
    80004ae0:	60a2                	ld	ra,8(sp)
    80004ae2:	6402                	ld	s0,0(sp)
    80004ae4:	0141                	addi	sp,sp,16
    80004ae6:	8082                	ret

0000000080004ae8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004ae8:	1101                	addi	sp,sp,-32
    80004aea:	ec06                	sd	ra,24(sp)
    80004aec:	e822                	sd	s0,16(sp)
    80004aee:	e426                	sd	s1,8(sp)
    80004af0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004af2:	00022517          	auipc	a0,0x22
    80004af6:	a4650513          	addi	a0,a0,-1466 # 80026538 <ftable>
    80004afa:	ffffc097          	auipc	ra,0xffffc
    80004afe:	13e080e7          	jalr	318(ra) # 80000c38 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b02:	00022497          	auipc	s1,0x22
    80004b06:	a4e48493          	addi	s1,s1,-1458 # 80026550 <ftable+0x18>
    80004b0a:	00023717          	auipc	a4,0x23
    80004b0e:	9e670713          	addi	a4,a4,-1562 # 800274f0 <disk>
    if(f->ref == 0){
    80004b12:	40dc                	lw	a5,4(s1)
    80004b14:	cf99                	beqz	a5,80004b32 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b16:	02848493          	addi	s1,s1,40
    80004b1a:	fee49ce3          	bne	s1,a4,80004b12 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b1e:	00022517          	auipc	a0,0x22
    80004b22:	a1a50513          	addi	a0,a0,-1510 # 80026538 <ftable>
    80004b26:	ffffc097          	auipc	ra,0xffffc
    80004b2a:	1c6080e7          	jalr	454(ra) # 80000cec <release>
  return 0;
    80004b2e:	4481                	li	s1,0
    80004b30:	a819                	j	80004b46 <filealloc+0x5e>
      f->ref = 1;
    80004b32:	4785                	li	a5,1
    80004b34:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b36:	00022517          	auipc	a0,0x22
    80004b3a:	a0250513          	addi	a0,a0,-1534 # 80026538 <ftable>
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	1ae080e7          	jalr	430(ra) # 80000cec <release>
}
    80004b46:	8526                	mv	a0,s1
    80004b48:	60e2                	ld	ra,24(sp)
    80004b4a:	6442                	ld	s0,16(sp)
    80004b4c:	64a2                	ld	s1,8(sp)
    80004b4e:	6105                	addi	sp,sp,32
    80004b50:	8082                	ret

0000000080004b52 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b52:	1101                	addi	sp,sp,-32
    80004b54:	ec06                	sd	ra,24(sp)
    80004b56:	e822                	sd	s0,16(sp)
    80004b58:	e426                	sd	s1,8(sp)
    80004b5a:	1000                	addi	s0,sp,32
    80004b5c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b5e:	00022517          	auipc	a0,0x22
    80004b62:	9da50513          	addi	a0,a0,-1574 # 80026538 <ftable>
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	0d2080e7          	jalr	210(ra) # 80000c38 <acquire>
  if(f->ref < 1)
    80004b6e:	40dc                	lw	a5,4(s1)
    80004b70:	02f05263          	blez	a5,80004b94 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b74:	2785                	addiw	a5,a5,1
    80004b76:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b78:	00022517          	auipc	a0,0x22
    80004b7c:	9c050513          	addi	a0,a0,-1600 # 80026538 <ftable>
    80004b80:	ffffc097          	auipc	ra,0xffffc
    80004b84:	16c080e7          	jalr	364(ra) # 80000cec <release>
  return f;
}
    80004b88:	8526                	mv	a0,s1
    80004b8a:	60e2                	ld	ra,24(sp)
    80004b8c:	6442                	ld	s0,16(sp)
    80004b8e:	64a2                	ld	s1,8(sp)
    80004b90:	6105                	addi	sp,sp,32
    80004b92:	8082                	ret
    panic("filedup");
    80004b94:	00004517          	auipc	a0,0x4
    80004b98:	9fc50513          	addi	a0,a0,-1540 # 80008590 <etext+0x590>
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	9c4080e7          	jalr	-1596(ra) # 80000560 <panic>

0000000080004ba4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ba4:	7139                	addi	sp,sp,-64
    80004ba6:	fc06                	sd	ra,56(sp)
    80004ba8:	f822                	sd	s0,48(sp)
    80004baa:	f426                	sd	s1,40(sp)
    80004bac:	0080                	addi	s0,sp,64
    80004bae:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bb0:	00022517          	auipc	a0,0x22
    80004bb4:	98850513          	addi	a0,a0,-1656 # 80026538 <ftable>
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	080080e7          	jalr	128(ra) # 80000c38 <acquire>
  if(f->ref < 1)
    80004bc0:	40dc                	lw	a5,4(s1)
    80004bc2:	04f05c63          	blez	a5,80004c1a <fileclose+0x76>
    panic("fileclose");
  if(--f->ref > 0){
    80004bc6:	37fd                	addiw	a5,a5,-1
    80004bc8:	0007871b          	sext.w	a4,a5
    80004bcc:	c0dc                	sw	a5,4(s1)
    80004bce:	06e04263          	bgtz	a4,80004c32 <fileclose+0x8e>
    80004bd2:	f04a                	sd	s2,32(sp)
    80004bd4:	ec4e                	sd	s3,24(sp)
    80004bd6:	e852                	sd	s4,16(sp)
    80004bd8:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004bda:	0004a903          	lw	s2,0(s1)
    80004bde:	0094ca83          	lbu	s5,9(s1)
    80004be2:	0104ba03          	ld	s4,16(s1)
    80004be6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bea:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004bee:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004bf2:	00022517          	auipc	a0,0x22
    80004bf6:	94650513          	addi	a0,a0,-1722 # 80026538 <ftable>
    80004bfa:	ffffc097          	auipc	ra,0xffffc
    80004bfe:	0f2080e7          	jalr	242(ra) # 80000cec <release>

  if(ff.type == FD_PIPE){
    80004c02:	4785                	li	a5,1
    80004c04:	04f90463          	beq	s2,a5,80004c4c <fileclose+0xa8>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c08:	3979                	addiw	s2,s2,-2
    80004c0a:	4785                	li	a5,1
    80004c0c:	0527fb63          	bgeu	a5,s2,80004c62 <fileclose+0xbe>
    80004c10:	7902                	ld	s2,32(sp)
    80004c12:	69e2                	ld	s3,24(sp)
    80004c14:	6a42                	ld	s4,16(sp)
    80004c16:	6aa2                	ld	s5,8(sp)
    80004c18:	a02d                	j	80004c42 <fileclose+0x9e>
    80004c1a:	f04a                	sd	s2,32(sp)
    80004c1c:	ec4e                	sd	s3,24(sp)
    80004c1e:	e852                	sd	s4,16(sp)
    80004c20:	e456                	sd	s5,8(sp)
    panic("fileclose");
    80004c22:	00004517          	auipc	a0,0x4
    80004c26:	97650513          	addi	a0,a0,-1674 # 80008598 <etext+0x598>
    80004c2a:	ffffc097          	auipc	ra,0xffffc
    80004c2e:	936080e7          	jalr	-1738(ra) # 80000560 <panic>
    release(&ftable.lock);
    80004c32:	00022517          	auipc	a0,0x22
    80004c36:	90650513          	addi	a0,a0,-1786 # 80026538 <ftable>
    80004c3a:	ffffc097          	auipc	ra,0xffffc
    80004c3e:	0b2080e7          	jalr	178(ra) # 80000cec <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    80004c42:	70e2                	ld	ra,56(sp)
    80004c44:	7442                	ld	s0,48(sp)
    80004c46:	74a2                	ld	s1,40(sp)
    80004c48:	6121                	addi	sp,sp,64
    80004c4a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c4c:	85d6                	mv	a1,s5
    80004c4e:	8552                	mv	a0,s4
    80004c50:	00000097          	auipc	ra,0x0
    80004c54:	3a2080e7          	jalr	930(ra) # 80004ff2 <pipeclose>
    80004c58:	7902                	ld	s2,32(sp)
    80004c5a:	69e2                	ld	s3,24(sp)
    80004c5c:	6a42                	ld	s4,16(sp)
    80004c5e:	6aa2                	ld	s5,8(sp)
    80004c60:	b7cd                	j	80004c42 <fileclose+0x9e>
    begin_op();
    80004c62:	00000097          	auipc	ra,0x0
    80004c66:	a78080e7          	jalr	-1416(ra) # 800046da <begin_op>
    iput(ff.ip);
    80004c6a:	854e                	mv	a0,s3
    80004c6c:	fffff097          	auipc	ra,0xfffff
    80004c70:	25e080e7          	jalr	606(ra) # 80003eca <iput>
    end_op();
    80004c74:	00000097          	auipc	ra,0x0
    80004c78:	ae0080e7          	jalr	-1312(ra) # 80004754 <end_op>
    80004c7c:	7902                	ld	s2,32(sp)
    80004c7e:	69e2                	ld	s3,24(sp)
    80004c80:	6a42                	ld	s4,16(sp)
    80004c82:	6aa2                	ld	s5,8(sp)
    80004c84:	bf7d                	j	80004c42 <fileclose+0x9e>

0000000080004c86 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c86:	715d                	addi	sp,sp,-80
    80004c88:	e486                	sd	ra,72(sp)
    80004c8a:	e0a2                	sd	s0,64(sp)
    80004c8c:	fc26                	sd	s1,56(sp)
    80004c8e:	f44e                	sd	s3,40(sp)
    80004c90:	0880                	addi	s0,sp,80
    80004c92:	84aa                	mv	s1,a0
    80004c94:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c96:	ffffd097          	auipc	ra,0xffffd
    80004c9a:	db4080e7          	jalr	-588(ra) # 80001a4a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c9e:	409c                	lw	a5,0(s1)
    80004ca0:	37f9                	addiw	a5,a5,-2
    80004ca2:	4705                	li	a4,1
    80004ca4:	04f76863          	bltu	a4,a5,80004cf4 <filestat+0x6e>
    80004ca8:	f84a                	sd	s2,48(sp)
    80004caa:	892a                	mv	s2,a0
    ilock(f->ip);
    80004cac:	6c88                	ld	a0,24(s1)
    80004cae:	fffff097          	auipc	ra,0xfffff
    80004cb2:	05e080e7          	jalr	94(ra) # 80003d0c <ilock>
    stati(f->ip, &st);
    80004cb6:	fb840593          	addi	a1,s0,-72
    80004cba:	6c88                	ld	a0,24(s1)
    80004cbc:	fffff097          	auipc	ra,0xfffff
    80004cc0:	2de080e7          	jalr	734(ra) # 80003f9a <stati>
    iunlock(f->ip);
    80004cc4:	6c88                	ld	a0,24(s1)
    80004cc6:	fffff097          	auipc	ra,0xfffff
    80004cca:	10c080e7          	jalr	268(ra) # 80003dd2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cce:	46e1                	li	a3,24
    80004cd0:	fb840613          	addi	a2,s0,-72
    80004cd4:	85ce                	mv	a1,s3
    80004cd6:	05093503          	ld	a0,80(s2)
    80004cda:	ffffd097          	auipc	ra,0xffffd
    80004cde:	a08080e7          	jalr	-1528(ra) # 800016e2 <copyout>
    80004ce2:	41f5551b          	sraiw	a0,a0,0x1f
    80004ce6:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    80004ce8:	60a6                	ld	ra,72(sp)
    80004cea:	6406                	ld	s0,64(sp)
    80004cec:	74e2                	ld	s1,56(sp)
    80004cee:	79a2                	ld	s3,40(sp)
    80004cf0:	6161                	addi	sp,sp,80
    80004cf2:	8082                	ret
  return -1;
    80004cf4:	557d                	li	a0,-1
    80004cf6:	bfcd                	j	80004ce8 <filestat+0x62>

0000000080004cf8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004cf8:	7179                	addi	sp,sp,-48
    80004cfa:	f406                	sd	ra,40(sp)
    80004cfc:	f022                	sd	s0,32(sp)
    80004cfe:	e84a                	sd	s2,16(sp)
    80004d00:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d02:	00854783          	lbu	a5,8(a0)
    80004d06:	cbc5                	beqz	a5,80004db6 <fileread+0xbe>
    80004d08:	ec26                	sd	s1,24(sp)
    80004d0a:	e44e                	sd	s3,8(sp)
    80004d0c:	84aa                	mv	s1,a0
    80004d0e:	89ae                	mv	s3,a1
    80004d10:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d12:	411c                	lw	a5,0(a0)
    80004d14:	4705                	li	a4,1
    80004d16:	04e78963          	beq	a5,a4,80004d68 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d1a:	470d                	li	a4,3
    80004d1c:	04e78f63          	beq	a5,a4,80004d7a <fileread+0x82>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d20:	4709                	li	a4,2
    80004d22:	08e79263          	bne	a5,a4,80004da6 <fileread+0xae>
    ilock(f->ip);
    80004d26:	6d08                	ld	a0,24(a0)
    80004d28:	fffff097          	auipc	ra,0xfffff
    80004d2c:	fe4080e7          	jalr	-28(ra) # 80003d0c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d30:	874a                	mv	a4,s2
    80004d32:	5094                	lw	a3,32(s1)
    80004d34:	864e                	mv	a2,s3
    80004d36:	4585                	li	a1,1
    80004d38:	6c88                	ld	a0,24(s1)
    80004d3a:	fffff097          	auipc	ra,0xfffff
    80004d3e:	28a080e7          	jalr	650(ra) # 80003fc4 <readi>
    80004d42:	892a                	mv	s2,a0
    80004d44:	00a05563          	blez	a0,80004d4e <fileread+0x56>
      f->off += r;
    80004d48:	509c                	lw	a5,32(s1)
    80004d4a:	9fa9                	addw	a5,a5,a0
    80004d4c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d4e:	6c88                	ld	a0,24(s1)
    80004d50:	fffff097          	auipc	ra,0xfffff
    80004d54:	082080e7          	jalr	130(ra) # 80003dd2 <iunlock>
    80004d58:	64e2                	ld	s1,24(sp)
    80004d5a:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    80004d5c:	854a                	mv	a0,s2
    80004d5e:	70a2                	ld	ra,40(sp)
    80004d60:	7402                	ld	s0,32(sp)
    80004d62:	6942                	ld	s2,16(sp)
    80004d64:	6145                	addi	sp,sp,48
    80004d66:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d68:	6908                	ld	a0,16(a0)
    80004d6a:	00000097          	auipc	ra,0x0
    80004d6e:	400080e7          	jalr	1024(ra) # 8000516a <piperead>
    80004d72:	892a                	mv	s2,a0
    80004d74:	64e2                	ld	s1,24(sp)
    80004d76:	69a2                	ld	s3,8(sp)
    80004d78:	b7d5                	j	80004d5c <fileread+0x64>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d7a:	02451783          	lh	a5,36(a0)
    80004d7e:	03079693          	slli	a3,a5,0x30
    80004d82:	92c1                	srli	a3,a3,0x30
    80004d84:	4725                	li	a4,9
    80004d86:	02d76a63          	bltu	a4,a3,80004dba <fileread+0xc2>
    80004d8a:	0792                	slli	a5,a5,0x4
    80004d8c:	00021717          	auipc	a4,0x21
    80004d90:	70c70713          	addi	a4,a4,1804 # 80026498 <devsw>
    80004d94:	97ba                	add	a5,a5,a4
    80004d96:	639c                	ld	a5,0(a5)
    80004d98:	c78d                	beqz	a5,80004dc2 <fileread+0xca>
    r = devsw[f->major].read(1, addr, n);
    80004d9a:	4505                	li	a0,1
    80004d9c:	9782                	jalr	a5
    80004d9e:	892a                	mv	s2,a0
    80004da0:	64e2                	ld	s1,24(sp)
    80004da2:	69a2                	ld	s3,8(sp)
    80004da4:	bf65                	j	80004d5c <fileread+0x64>
    panic("fileread");
    80004da6:	00004517          	auipc	a0,0x4
    80004daa:	80250513          	addi	a0,a0,-2046 # 800085a8 <etext+0x5a8>
    80004dae:	ffffb097          	auipc	ra,0xffffb
    80004db2:	7b2080e7          	jalr	1970(ra) # 80000560 <panic>
    return -1;
    80004db6:	597d                	li	s2,-1
    80004db8:	b755                	j	80004d5c <fileread+0x64>
      return -1;
    80004dba:	597d                	li	s2,-1
    80004dbc:	64e2                	ld	s1,24(sp)
    80004dbe:	69a2                	ld	s3,8(sp)
    80004dc0:	bf71                	j	80004d5c <fileread+0x64>
    80004dc2:	597d                	li	s2,-1
    80004dc4:	64e2                	ld	s1,24(sp)
    80004dc6:	69a2                	ld	s3,8(sp)
    80004dc8:	bf51                	j	80004d5c <fileread+0x64>

0000000080004dca <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004dca:	00954783          	lbu	a5,9(a0)
    80004dce:	12078963          	beqz	a5,80004f00 <filewrite+0x136>
{
    80004dd2:	715d                	addi	sp,sp,-80
    80004dd4:	e486                	sd	ra,72(sp)
    80004dd6:	e0a2                	sd	s0,64(sp)
    80004dd8:	f84a                	sd	s2,48(sp)
    80004dda:	f052                	sd	s4,32(sp)
    80004ddc:	e85a                	sd	s6,16(sp)
    80004dde:	0880                	addi	s0,sp,80
    80004de0:	892a                	mv	s2,a0
    80004de2:	8b2e                	mv	s6,a1
    80004de4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004de6:	411c                	lw	a5,0(a0)
    80004de8:	4705                	li	a4,1
    80004dea:	02e78763          	beq	a5,a4,80004e18 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dee:	470d                	li	a4,3
    80004df0:	02e78a63          	beq	a5,a4,80004e24 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004df4:	4709                	li	a4,2
    80004df6:	0ee79863          	bne	a5,a4,80004ee6 <filewrite+0x11c>
    80004dfa:	f44e                	sd	s3,40(sp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004dfc:	0cc05463          	blez	a2,80004ec4 <filewrite+0xfa>
    80004e00:	fc26                	sd	s1,56(sp)
    80004e02:	ec56                	sd	s5,24(sp)
    80004e04:	e45e                	sd	s7,8(sp)
    80004e06:	e062                	sd	s8,0(sp)
    int i = 0;
    80004e08:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004e0a:	6b85                	lui	s7,0x1
    80004e0c:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004e10:	6c05                	lui	s8,0x1
    80004e12:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004e16:	a851                	j	80004eaa <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004e18:	6908                	ld	a0,16(a0)
    80004e1a:	00000097          	auipc	ra,0x0
    80004e1e:	248080e7          	jalr	584(ra) # 80005062 <pipewrite>
    80004e22:	a85d                	j	80004ed8 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e24:	02451783          	lh	a5,36(a0)
    80004e28:	03079693          	slli	a3,a5,0x30
    80004e2c:	92c1                	srli	a3,a3,0x30
    80004e2e:	4725                	li	a4,9
    80004e30:	0cd76a63          	bltu	a4,a3,80004f04 <filewrite+0x13a>
    80004e34:	0792                	slli	a5,a5,0x4
    80004e36:	00021717          	auipc	a4,0x21
    80004e3a:	66270713          	addi	a4,a4,1634 # 80026498 <devsw>
    80004e3e:	97ba                	add	a5,a5,a4
    80004e40:	679c                	ld	a5,8(a5)
    80004e42:	c3f9                	beqz	a5,80004f08 <filewrite+0x13e>
    ret = devsw[f->major].write(1, addr, n);
    80004e44:	4505                	li	a0,1
    80004e46:	9782                	jalr	a5
    80004e48:	a841                	j	80004ed8 <filewrite+0x10e>
      if(n1 > max)
    80004e4a:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004e4e:	00000097          	auipc	ra,0x0
    80004e52:	88c080e7          	jalr	-1908(ra) # 800046da <begin_op>
      ilock(f->ip);
    80004e56:	01893503          	ld	a0,24(s2)
    80004e5a:	fffff097          	auipc	ra,0xfffff
    80004e5e:	eb2080e7          	jalr	-334(ra) # 80003d0c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e62:	8756                	mv	a4,s5
    80004e64:	02092683          	lw	a3,32(s2)
    80004e68:	01698633          	add	a2,s3,s6
    80004e6c:	4585                	li	a1,1
    80004e6e:	01893503          	ld	a0,24(s2)
    80004e72:	fffff097          	auipc	ra,0xfffff
    80004e76:	262080e7          	jalr	610(ra) # 800040d4 <writei>
    80004e7a:	84aa                	mv	s1,a0
    80004e7c:	00a05763          	blez	a0,80004e8a <filewrite+0xc0>
        f->off += r;
    80004e80:	02092783          	lw	a5,32(s2)
    80004e84:	9fa9                	addw	a5,a5,a0
    80004e86:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e8a:	01893503          	ld	a0,24(s2)
    80004e8e:	fffff097          	auipc	ra,0xfffff
    80004e92:	f44080e7          	jalr	-188(ra) # 80003dd2 <iunlock>
      end_op();
    80004e96:	00000097          	auipc	ra,0x0
    80004e9a:	8be080e7          	jalr	-1858(ra) # 80004754 <end_op>

      if(r != n1){
    80004e9e:	029a9563          	bne	s5,s1,80004ec8 <filewrite+0xfe>
        // error from writei
        break;
      }
      i += r;
    80004ea2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ea6:	0149da63          	bge	s3,s4,80004eba <filewrite+0xf0>
      int n1 = n - i;
    80004eaa:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004eae:	0004879b          	sext.w	a5,s1
    80004eb2:	f8fbdce3          	bge	s7,a5,80004e4a <filewrite+0x80>
    80004eb6:	84e2                	mv	s1,s8
    80004eb8:	bf49                	j	80004e4a <filewrite+0x80>
    80004eba:	74e2                	ld	s1,56(sp)
    80004ebc:	6ae2                	ld	s5,24(sp)
    80004ebe:	6ba2                	ld	s7,8(sp)
    80004ec0:	6c02                	ld	s8,0(sp)
    80004ec2:	a039                	j	80004ed0 <filewrite+0x106>
    int i = 0;
    80004ec4:	4981                	li	s3,0
    80004ec6:	a029                	j	80004ed0 <filewrite+0x106>
    80004ec8:	74e2                	ld	s1,56(sp)
    80004eca:	6ae2                	ld	s5,24(sp)
    80004ecc:	6ba2                	ld	s7,8(sp)
    80004ece:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    80004ed0:	033a1e63          	bne	s4,s3,80004f0c <filewrite+0x142>
    80004ed4:	8552                	mv	a0,s4
    80004ed6:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ed8:	60a6                	ld	ra,72(sp)
    80004eda:	6406                	ld	s0,64(sp)
    80004edc:	7942                	ld	s2,48(sp)
    80004ede:	7a02                	ld	s4,32(sp)
    80004ee0:	6b42                	ld	s6,16(sp)
    80004ee2:	6161                	addi	sp,sp,80
    80004ee4:	8082                	ret
    80004ee6:	fc26                	sd	s1,56(sp)
    80004ee8:	f44e                	sd	s3,40(sp)
    80004eea:	ec56                	sd	s5,24(sp)
    80004eec:	e45e                	sd	s7,8(sp)
    80004eee:	e062                	sd	s8,0(sp)
    panic("filewrite");
    80004ef0:	00003517          	auipc	a0,0x3
    80004ef4:	6c850513          	addi	a0,a0,1736 # 800085b8 <etext+0x5b8>
    80004ef8:	ffffb097          	auipc	ra,0xffffb
    80004efc:	668080e7          	jalr	1640(ra) # 80000560 <panic>
    return -1;
    80004f00:	557d                	li	a0,-1
}
    80004f02:	8082                	ret
      return -1;
    80004f04:	557d                	li	a0,-1
    80004f06:	bfc9                	j	80004ed8 <filewrite+0x10e>
    80004f08:	557d                	li	a0,-1
    80004f0a:	b7f9                	j	80004ed8 <filewrite+0x10e>
    ret = (i == n ? n : -1);
    80004f0c:	557d                	li	a0,-1
    80004f0e:	79a2                	ld	s3,40(sp)
    80004f10:	b7e1                	j	80004ed8 <filewrite+0x10e>

0000000080004f12 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f12:	7179                	addi	sp,sp,-48
    80004f14:	f406                	sd	ra,40(sp)
    80004f16:	f022                	sd	s0,32(sp)
    80004f18:	ec26                	sd	s1,24(sp)
    80004f1a:	e052                	sd	s4,0(sp)
    80004f1c:	1800                	addi	s0,sp,48
    80004f1e:	84aa                	mv	s1,a0
    80004f20:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f22:	0005b023          	sd	zero,0(a1)
    80004f26:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f2a:	00000097          	auipc	ra,0x0
    80004f2e:	bbe080e7          	jalr	-1090(ra) # 80004ae8 <filealloc>
    80004f32:	e088                	sd	a0,0(s1)
    80004f34:	cd49                	beqz	a0,80004fce <pipealloc+0xbc>
    80004f36:	00000097          	auipc	ra,0x0
    80004f3a:	bb2080e7          	jalr	-1102(ra) # 80004ae8 <filealloc>
    80004f3e:	00aa3023          	sd	a0,0(s4)
    80004f42:	c141                	beqz	a0,80004fc2 <pipealloc+0xb0>
    80004f44:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f46:	ffffc097          	auipc	ra,0xffffc
    80004f4a:	c02080e7          	jalr	-1022(ra) # 80000b48 <kalloc>
    80004f4e:	892a                	mv	s2,a0
    80004f50:	c13d                	beqz	a0,80004fb6 <pipealloc+0xa4>
    80004f52:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    80004f54:	4985                	li	s3,1
    80004f56:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f5a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f5e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f62:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f66:	00003597          	auipc	a1,0x3
    80004f6a:	66258593          	addi	a1,a1,1634 # 800085c8 <etext+0x5c8>
    80004f6e:	ffffc097          	auipc	ra,0xffffc
    80004f72:	c3a080e7          	jalr	-966(ra) # 80000ba8 <initlock>
  (*f0)->type = FD_PIPE;
    80004f76:	609c                	ld	a5,0(s1)
    80004f78:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f7c:	609c                	ld	a5,0(s1)
    80004f7e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f82:	609c                	ld	a5,0(s1)
    80004f84:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f88:	609c                	ld	a5,0(s1)
    80004f8a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f8e:	000a3783          	ld	a5,0(s4)
    80004f92:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f96:	000a3783          	ld	a5,0(s4)
    80004f9a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f9e:	000a3783          	ld	a5,0(s4)
    80004fa2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004fa6:	000a3783          	ld	a5,0(s4)
    80004faa:	0127b823          	sd	s2,16(a5)
  return 0;
    80004fae:	4501                	li	a0,0
    80004fb0:	6942                	ld	s2,16(sp)
    80004fb2:	69a2                	ld	s3,8(sp)
    80004fb4:	a03d                	j	80004fe2 <pipealloc+0xd0>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004fb6:	6088                	ld	a0,0(s1)
    80004fb8:	c119                	beqz	a0,80004fbe <pipealloc+0xac>
    80004fba:	6942                	ld	s2,16(sp)
    80004fbc:	a029                	j	80004fc6 <pipealloc+0xb4>
    80004fbe:	6942                	ld	s2,16(sp)
    80004fc0:	a039                	j	80004fce <pipealloc+0xbc>
    80004fc2:	6088                	ld	a0,0(s1)
    80004fc4:	c50d                	beqz	a0,80004fee <pipealloc+0xdc>
    fileclose(*f0);
    80004fc6:	00000097          	auipc	ra,0x0
    80004fca:	bde080e7          	jalr	-1058(ra) # 80004ba4 <fileclose>
  if(*f1)
    80004fce:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004fd2:	557d                	li	a0,-1
  if(*f1)
    80004fd4:	c799                	beqz	a5,80004fe2 <pipealloc+0xd0>
    fileclose(*f1);
    80004fd6:	853e                	mv	a0,a5
    80004fd8:	00000097          	auipc	ra,0x0
    80004fdc:	bcc080e7          	jalr	-1076(ra) # 80004ba4 <fileclose>
  return -1;
    80004fe0:	557d                	li	a0,-1
}
    80004fe2:	70a2                	ld	ra,40(sp)
    80004fe4:	7402                	ld	s0,32(sp)
    80004fe6:	64e2                	ld	s1,24(sp)
    80004fe8:	6a02                	ld	s4,0(sp)
    80004fea:	6145                	addi	sp,sp,48
    80004fec:	8082                	ret
  return -1;
    80004fee:	557d                	li	a0,-1
    80004ff0:	bfcd                	j	80004fe2 <pipealloc+0xd0>

0000000080004ff2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ff2:	1101                	addi	sp,sp,-32
    80004ff4:	ec06                	sd	ra,24(sp)
    80004ff6:	e822                	sd	s0,16(sp)
    80004ff8:	e426                	sd	s1,8(sp)
    80004ffa:	e04a                	sd	s2,0(sp)
    80004ffc:	1000                	addi	s0,sp,32
    80004ffe:	84aa                	mv	s1,a0
    80005000:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005002:	ffffc097          	auipc	ra,0xffffc
    80005006:	c36080e7          	jalr	-970(ra) # 80000c38 <acquire>
  if(writable){
    8000500a:	02090d63          	beqz	s2,80005044 <pipeclose+0x52>
    pi->writeopen = 0;
    8000500e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005012:	21848513          	addi	a0,s1,536
    80005016:	ffffd097          	auipc	ra,0xffffd
    8000501a:	2fc080e7          	jalr	764(ra) # 80002312 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000501e:	2204b783          	ld	a5,544(s1)
    80005022:	eb95                	bnez	a5,80005056 <pipeclose+0x64>
    release(&pi->lock);
    80005024:	8526                	mv	a0,s1
    80005026:	ffffc097          	auipc	ra,0xffffc
    8000502a:	cc6080e7          	jalr	-826(ra) # 80000cec <release>
    kfree((char*)pi);
    8000502e:	8526                	mv	a0,s1
    80005030:	ffffc097          	auipc	ra,0xffffc
    80005034:	a1a080e7          	jalr	-1510(ra) # 80000a4a <kfree>
  } else
    release(&pi->lock);
}
    80005038:	60e2                	ld	ra,24(sp)
    8000503a:	6442                	ld	s0,16(sp)
    8000503c:	64a2                	ld	s1,8(sp)
    8000503e:	6902                	ld	s2,0(sp)
    80005040:	6105                	addi	sp,sp,32
    80005042:	8082                	ret
    pi->readopen = 0;
    80005044:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005048:	21c48513          	addi	a0,s1,540
    8000504c:	ffffd097          	auipc	ra,0xffffd
    80005050:	2c6080e7          	jalr	710(ra) # 80002312 <wakeup>
    80005054:	b7e9                	j	8000501e <pipeclose+0x2c>
    release(&pi->lock);
    80005056:	8526                	mv	a0,s1
    80005058:	ffffc097          	auipc	ra,0xffffc
    8000505c:	c94080e7          	jalr	-876(ra) # 80000cec <release>
}
    80005060:	bfe1                	j	80005038 <pipeclose+0x46>

0000000080005062 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005062:	711d                	addi	sp,sp,-96
    80005064:	ec86                	sd	ra,88(sp)
    80005066:	e8a2                	sd	s0,80(sp)
    80005068:	e4a6                	sd	s1,72(sp)
    8000506a:	e0ca                	sd	s2,64(sp)
    8000506c:	fc4e                	sd	s3,56(sp)
    8000506e:	f852                	sd	s4,48(sp)
    80005070:	f456                	sd	s5,40(sp)
    80005072:	1080                	addi	s0,sp,96
    80005074:	84aa                	mv	s1,a0
    80005076:	8aae                	mv	s5,a1
    80005078:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000507a:	ffffd097          	auipc	ra,0xffffd
    8000507e:	9d0080e7          	jalr	-1584(ra) # 80001a4a <myproc>
    80005082:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005084:	8526                	mv	a0,s1
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	bb2080e7          	jalr	-1102(ra) # 80000c38 <acquire>
  while(i < n){
    8000508e:	0d405863          	blez	s4,8000515e <pipewrite+0xfc>
    80005092:	f05a                	sd	s6,32(sp)
    80005094:	ec5e                	sd	s7,24(sp)
    80005096:	e862                	sd	s8,16(sp)
  int i = 0;
    80005098:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000509a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000509c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800050a0:	21c48b93          	addi	s7,s1,540
    800050a4:	a089                	j	800050e6 <pipewrite+0x84>
      release(&pi->lock);
    800050a6:	8526                	mv	a0,s1
    800050a8:	ffffc097          	auipc	ra,0xffffc
    800050ac:	c44080e7          	jalr	-956(ra) # 80000cec <release>
      return -1;
    800050b0:	597d                	li	s2,-1
    800050b2:	7b02                	ld	s6,32(sp)
    800050b4:	6be2                	ld	s7,24(sp)
    800050b6:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800050b8:	854a                	mv	a0,s2
    800050ba:	60e6                	ld	ra,88(sp)
    800050bc:	6446                	ld	s0,80(sp)
    800050be:	64a6                	ld	s1,72(sp)
    800050c0:	6906                	ld	s2,64(sp)
    800050c2:	79e2                	ld	s3,56(sp)
    800050c4:	7a42                	ld	s4,48(sp)
    800050c6:	7aa2                	ld	s5,40(sp)
    800050c8:	6125                	addi	sp,sp,96
    800050ca:	8082                	ret
      wakeup(&pi->nread);
    800050cc:	8562                	mv	a0,s8
    800050ce:	ffffd097          	auipc	ra,0xffffd
    800050d2:	244080e7          	jalr	580(ra) # 80002312 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800050d6:	85a6                	mv	a1,s1
    800050d8:	855e                	mv	a0,s7
    800050da:	ffffd097          	auipc	ra,0xffffd
    800050de:	1d4080e7          	jalr	468(ra) # 800022ae <sleep>
  while(i < n){
    800050e2:	05495f63          	bge	s2,s4,80005140 <pipewrite+0xde>
    if(pi->readopen == 0 || killed(pr)){
    800050e6:	2204a783          	lw	a5,544(s1)
    800050ea:	dfd5                	beqz	a5,800050a6 <pipewrite+0x44>
    800050ec:	854e                	mv	a0,s3
    800050ee:	ffffd097          	auipc	ra,0xffffd
    800050f2:	480080e7          	jalr	1152(ra) # 8000256e <killed>
    800050f6:	f945                	bnez	a0,800050a6 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050f8:	2184a783          	lw	a5,536(s1)
    800050fc:	21c4a703          	lw	a4,540(s1)
    80005100:	2007879b          	addiw	a5,a5,512
    80005104:	fcf704e3          	beq	a4,a5,800050cc <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005108:	4685                	li	a3,1
    8000510a:	01590633          	add	a2,s2,s5
    8000510e:	faf40593          	addi	a1,s0,-81
    80005112:	0509b503          	ld	a0,80(s3)
    80005116:	ffffc097          	auipc	ra,0xffffc
    8000511a:	658080e7          	jalr	1624(ra) # 8000176e <copyin>
    8000511e:	05650263          	beq	a0,s6,80005162 <pipewrite+0x100>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005122:	21c4a783          	lw	a5,540(s1)
    80005126:	0017871b          	addiw	a4,a5,1
    8000512a:	20e4ae23          	sw	a4,540(s1)
    8000512e:	1ff7f793          	andi	a5,a5,511
    80005132:	97a6                	add	a5,a5,s1
    80005134:	faf44703          	lbu	a4,-81(s0)
    80005138:	00e78c23          	sb	a4,24(a5)
      i++;
    8000513c:	2905                	addiw	s2,s2,1
    8000513e:	b755                	j	800050e2 <pipewrite+0x80>
    80005140:	7b02                	ld	s6,32(sp)
    80005142:	6be2                	ld	s7,24(sp)
    80005144:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    80005146:	21848513          	addi	a0,s1,536
    8000514a:	ffffd097          	auipc	ra,0xffffd
    8000514e:	1c8080e7          	jalr	456(ra) # 80002312 <wakeup>
  release(&pi->lock);
    80005152:	8526                	mv	a0,s1
    80005154:	ffffc097          	auipc	ra,0xffffc
    80005158:	b98080e7          	jalr	-1128(ra) # 80000cec <release>
  return i;
    8000515c:	bfb1                	j	800050b8 <pipewrite+0x56>
  int i = 0;
    8000515e:	4901                	li	s2,0
    80005160:	b7dd                	j	80005146 <pipewrite+0xe4>
    80005162:	7b02                	ld	s6,32(sp)
    80005164:	6be2                	ld	s7,24(sp)
    80005166:	6c42                	ld	s8,16(sp)
    80005168:	bff9                	j	80005146 <pipewrite+0xe4>

000000008000516a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000516a:	715d                	addi	sp,sp,-80
    8000516c:	e486                	sd	ra,72(sp)
    8000516e:	e0a2                	sd	s0,64(sp)
    80005170:	fc26                	sd	s1,56(sp)
    80005172:	f84a                	sd	s2,48(sp)
    80005174:	f44e                	sd	s3,40(sp)
    80005176:	f052                	sd	s4,32(sp)
    80005178:	ec56                	sd	s5,24(sp)
    8000517a:	0880                	addi	s0,sp,80
    8000517c:	84aa                	mv	s1,a0
    8000517e:	892e                	mv	s2,a1
    80005180:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005182:	ffffd097          	auipc	ra,0xffffd
    80005186:	8c8080e7          	jalr	-1848(ra) # 80001a4a <myproc>
    8000518a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000518c:	8526                	mv	a0,s1
    8000518e:	ffffc097          	auipc	ra,0xffffc
    80005192:	aaa080e7          	jalr	-1366(ra) # 80000c38 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005196:	2184a703          	lw	a4,536(s1)
    8000519a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000519e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051a2:	02f71963          	bne	a4,a5,800051d4 <piperead+0x6a>
    800051a6:	2244a783          	lw	a5,548(s1)
    800051aa:	cf95                	beqz	a5,800051e6 <piperead+0x7c>
    if(killed(pr)){
    800051ac:	8552                	mv	a0,s4
    800051ae:	ffffd097          	auipc	ra,0xffffd
    800051b2:	3c0080e7          	jalr	960(ra) # 8000256e <killed>
    800051b6:	e10d                	bnez	a0,800051d8 <piperead+0x6e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051b8:	85a6                	mv	a1,s1
    800051ba:	854e                	mv	a0,s3
    800051bc:	ffffd097          	auipc	ra,0xffffd
    800051c0:	0f2080e7          	jalr	242(ra) # 800022ae <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051c4:	2184a703          	lw	a4,536(s1)
    800051c8:	21c4a783          	lw	a5,540(s1)
    800051cc:	fcf70de3          	beq	a4,a5,800051a6 <piperead+0x3c>
    800051d0:	e85a                	sd	s6,16(sp)
    800051d2:	a819                	j	800051e8 <piperead+0x7e>
    800051d4:	e85a                	sd	s6,16(sp)
    800051d6:	a809                	j	800051e8 <piperead+0x7e>
      release(&pi->lock);
    800051d8:	8526                	mv	a0,s1
    800051da:	ffffc097          	auipc	ra,0xffffc
    800051de:	b12080e7          	jalr	-1262(ra) # 80000cec <release>
      return -1;
    800051e2:	59fd                	li	s3,-1
    800051e4:	a0a5                	j	8000524c <piperead+0xe2>
    800051e6:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051e8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051ea:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051ec:	05505463          	blez	s5,80005234 <piperead+0xca>
    if(pi->nread == pi->nwrite)
    800051f0:	2184a783          	lw	a5,536(s1)
    800051f4:	21c4a703          	lw	a4,540(s1)
    800051f8:	02f70e63          	beq	a4,a5,80005234 <piperead+0xca>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800051fc:	0017871b          	addiw	a4,a5,1
    80005200:	20e4ac23          	sw	a4,536(s1)
    80005204:	1ff7f793          	andi	a5,a5,511
    80005208:	97a6                	add	a5,a5,s1
    8000520a:	0187c783          	lbu	a5,24(a5)
    8000520e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005212:	4685                	li	a3,1
    80005214:	fbf40613          	addi	a2,s0,-65
    80005218:	85ca                	mv	a1,s2
    8000521a:	050a3503          	ld	a0,80(s4)
    8000521e:	ffffc097          	auipc	ra,0xffffc
    80005222:	4c4080e7          	jalr	1220(ra) # 800016e2 <copyout>
    80005226:	01650763          	beq	a0,s6,80005234 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000522a:	2985                	addiw	s3,s3,1
    8000522c:	0905                	addi	s2,s2,1
    8000522e:	fd3a91e3          	bne	s5,s3,800051f0 <piperead+0x86>
    80005232:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005234:	21c48513          	addi	a0,s1,540
    80005238:	ffffd097          	auipc	ra,0xffffd
    8000523c:	0da080e7          	jalr	218(ra) # 80002312 <wakeup>
  release(&pi->lock);
    80005240:	8526                	mv	a0,s1
    80005242:	ffffc097          	auipc	ra,0xffffc
    80005246:	aaa080e7          	jalr	-1366(ra) # 80000cec <release>
    8000524a:	6b42                	ld	s6,16(sp)
  return i;
}
    8000524c:	854e                	mv	a0,s3
    8000524e:	60a6                	ld	ra,72(sp)
    80005250:	6406                	ld	s0,64(sp)
    80005252:	74e2                	ld	s1,56(sp)
    80005254:	7942                	ld	s2,48(sp)
    80005256:	79a2                	ld	s3,40(sp)
    80005258:	7a02                	ld	s4,32(sp)
    8000525a:	6ae2                	ld	s5,24(sp)
    8000525c:	6161                	addi	sp,sp,80
    8000525e:	8082                	ret

0000000080005260 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005260:	1141                	addi	sp,sp,-16
    80005262:	e422                	sd	s0,8(sp)
    80005264:	0800                	addi	s0,sp,16
    80005266:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005268:	8905                	andi	a0,a0,1
    8000526a:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000526c:	8b89                	andi	a5,a5,2
    8000526e:	c399                	beqz	a5,80005274 <flags2perm+0x14>
      perm |= PTE_W;
    80005270:	00456513          	ori	a0,a0,4
    return perm;
}
    80005274:	6422                	ld	s0,8(sp)
    80005276:	0141                	addi	sp,sp,16
    80005278:	8082                	ret

000000008000527a <exec>:

int
exec(char *path, char **argv)
{
    8000527a:	df010113          	addi	sp,sp,-528
    8000527e:	20113423          	sd	ra,520(sp)
    80005282:	20813023          	sd	s0,512(sp)
    80005286:	ffa6                	sd	s1,504(sp)
    80005288:	fbca                	sd	s2,496(sp)
    8000528a:	0c00                	addi	s0,sp,528
    8000528c:	892a                	mv	s2,a0
    8000528e:	dea43c23          	sd	a0,-520(s0)
    80005292:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005296:	ffffc097          	auipc	ra,0xffffc
    8000529a:	7b4080e7          	jalr	1972(ra) # 80001a4a <myproc>
    8000529e:	84aa                	mv	s1,a0

  begin_op();
    800052a0:	fffff097          	auipc	ra,0xfffff
    800052a4:	43a080e7          	jalr	1082(ra) # 800046da <begin_op>

  if((ip = namei(path)) == 0){
    800052a8:	854a                	mv	a0,s2
    800052aa:	fffff097          	auipc	ra,0xfffff
    800052ae:	230080e7          	jalr	560(ra) # 800044da <namei>
    800052b2:	c135                	beqz	a0,80005316 <exec+0x9c>
    800052b4:	f3d2                	sd	s4,480(sp)
    800052b6:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	a54080e7          	jalr	-1452(ra) # 80003d0c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800052c0:	04000713          	li	a4,64
    800052c4:	4681                	li	a3,0
    800052c6:	e5040613          	addi	a2,s0,-432
    800052ca:	4581                	li	a1,0
    800052cc:	8552                	mv	a0,s4
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	cf6080e7          	jalr	-778(ra) # 80003fc4 <readi>
    800052d6:	04000793          	li	a5,64
    800052da:	00f51a63          	bne	a0,a5,800052ee <exec+0x74>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800052de:	e5042703          	lw	a4,-432(s0)
    800052e2:	464c47b7          	lui	a5,0x464c4
    800052e6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800052ea:	02f70c63          	beq	a4,a5,80005322 <exec+0xa8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800052ee:	8552                	mv	a0,s4
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	c82080e7          	jalr	-894(ra) # 80003f72 <iunlockput>
    end_op();
    800052f8:	fffff097          	auipc	ra,0xfffff
    800052fc:	45c080e7          	jalr	1116(ra) # 80004754 <end_op>
  }
  return -1;
    80005300:	557d                	li	a0,-1
    80005302:	7a1e                	ld	s4,480(sp)
}
    80005304:	20813083          	ld	ra,520(sp)
    80005308:	20013403          	ld	s0,512(sp)
    8000530c:	74fe                	ld	s1,504(sp)
    8000530e:	795e                	ld	s2,496(sp)
    80005310:	21010113          	addi	sp,sp,528
    80005314:	8082                	ret
    end_op();
    80005316:	fffff097          	auipc	ra,0xfffff
    8000531a:	43e080e7          	jalr	1086(ra) # 80004754 <end_op>
    return -1;
    8000531e:	557d                	li	a0,-1
    80005320:	b7d5                	j	80005304 <exec+0x8a>
    80005322:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    80005324:	8526                	mv	a0,s1
    80005326:	ffffc097          	auipc	ra,0xffffc
    8000532a:	7e8080e7          	jalr	2024(ra) # 80001b0e <proc_pagetable>
    8000532e:	8b2a                	mv	s6,a0
    80005330:	30050f63          	beqz	a0,8000564e <exec+0x3d4>
    80005334:	f7ce                	sd	s3,488(sp)
    80005336:	efd6                	sd	s5,472(sp)
    80005338:	e7de                	sd	s7,456(sp)
    8000533a:	e3e2                	sd	s8,448(sp)
    8000533c:	ff66                	sd	s9,440(sp)
    8000533e:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005340:	e7042d03          	lw	s10,-400(s0)
    80005344:	e8845783          	lhu	a5,-376(s0)
    80005348:	14078d63          	beqz	a5,800054a2 <exec+0x228>
    8000534c:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000534e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005350:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005352:	6c85                	lui	s9,0x1
    80005354:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005358:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8000535c:	6a85                	lui	s5,0x1
    8000535e:	a0b5                	j	800053ca <exec+0x150>
      panic("loadseg: address should exist");
    80005360:	00003517          	auipc	a0,0x3
    80005364:	27050513          	addi	a0,a0,624 # 800085d0 <etext+0x5d0>
    80005368:	ffffb097          	auipc	ra,0xffffb
    8000536c:	1f8080e7          	jalr	504(ra) # 80000560 <panic>
    if(sz - i < PGSIZE)
    80005370:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005372:	8726                	mv	a4,s1
    80005374:	012c06bb          	addw	a3,s8,s2
    80005378:	4581                	li	a1,0
    8000537a:	8552                	mv	a0,s4
    8000537c:	fffff097          	auipc	ra,0xfffff
    80005380:	c48080e7          	jalr	-952(ra) # 80003fc4 <readi>
    80005384:	2501                	sext.w	a0,a0
    80005386:	28a49863          	bne	s1,a0,80005616 <exec+0x39c>
  for(i = 0; i < sz; i += PGSIZE){
    8000538a:	012a893b          	addw	s2,s5,s2
    8000538e:	03397563          	bgeu	s2,s3,800053b8 <exec+0x13e>
    pa = walkaddr(pagetable, va + i);
    80005392:	02091593          	slli	a1,s2,0x20
    80005396:	9181                	srli	a1,a1,0x20
    80005398:	95de                	add	a1,a1,s7
    8000539a:	855a                	mv	a0,s6
    8000539c:	ffffc097          	auipc	ra,0xffffc
    800053a0:	d1a080e7          	jalr	-742(ra) # 800010b6 <walkaddr>
    800053a4:	862a                	mv	a2,a0
    if(pa == 0)
    800053a6:	dd4d                	beqz	a0,80005360 <exec+0xe6>
    if(sz - i < PGSIZE)
    800053a8:	412984bb          	subw	s1,s3,s2
    800053ac:	0004879b          	sext.w	a5,s1
    800053b0:	fcfcf0e3          	bgeu	s9,a5,80005370 <exec+0xf6>
    800053b4:	84d6                	mv	s1,s5
    800053b6:	bf6d                	j	80005370 <exec+0xf6>
    sz = sz1;
    800053b8:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053bc:	2d85                	addiw	s11,s11,1
    800053be:	038d0d1b          	addiw	s10,s10,56
    800053c2:	e8845783          	lhu	a5,-376(s0)
    800053c6:	08fdd663          	bge	s11,a5,80005452 <exec+0x1d8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053ca:	2d01                	sext.w	s10,s10
    800053cc:	03800713          	li	a4,56
    800053d0:	86ea                	mv	a3,s10
    800053d2:	e1840613          	addi	a2,s0,-488
    800053d6:	4581                	li	a1,0
    800053d8:	8552                	mv	a0,s4
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	bea080e7          	jalr	-1046(ra) # 80003fc4 <readi>
    800053e2:	03800793          	li	a5,56
    800053e6:	20f51063          	bne	a0,a5,800055e6 <exec+0x36c>
    if(ph.type != ELF_PROG_LOAD)
    800053ea:	e1842783          	lw	a5,-488(s0)
    800053ee:	4705                	li	a4,1
    800053f0:	fce796e3          	bne	a5,a4,800053bc <exec+0x142>
    if(ph.memsz < ph.filesz)
    800053f4:	e4043483          	ld	s1,-448(s0)
    800053f8:	e3843783          	ld	a5,-456(s0)
    800053fc:	1ef4e963          	bltu	s1,a5,800055ee <exec+0x374>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005400:	e2843783          	ld	a5,-472(s0)
    80005404:	94be                	add	s1,s1,a5
    80005406:	1ef4e863          	bltu	s1,a5,800055f6 <exec+0x37c>
    if(ph.vaddr % PGSIZE != 0)
    8000540a:	df043703          	ld	a4,-528(s0)
    8000540e:	8ff9                	and	a5,a5,a4
    80005410:	1e079763          	bnez	a5,800055fe <exec+0x384>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005414:	e1c42503          	lw	a0,-484(s0)
    80005418:	00000097          	auipc	ra,0x0
    8000541c:	e48080e7          	jalr	-440(ra) # 80005260 <flags2perm>
    80005420:	86aa                	mv	a3,a0
    80005422:	8626                	mv	a2,s1
    80005424:	85ca                	mv	a1,s2
    80005426:	855a                	mv	a0,s6
    80005428:	ffffc097          	auipc	ra,0xffffc
    8000542c:	052080e7          	jalr	82(ra) # 8000147a <uvmalloc>
    80005430:	e0a43423          	sd	a0,-504(s0)
    80005434:	1c050963          	beqz	a0,80005606 <exec+0x38c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005438:	e2843b83          	ld	s7,-472(s0)
    8000543c:	e2042c03          	lw	s8,-480(s0)
    80005440:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005444:	00098463          	beqz	s3,8000544c <exec+0x1d2>
    80005448:	4901                	li	s2,0
    8000544a:	b7a1                	j	80005392 <exec+0x118>
    sz = sz1;
    8000544c:	e0843903          	ld	s2,-504(s0)
    80005450:	b7b5                	j	800053bc <exec+0x142>
    80005452:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    80005454:	8552                	mv	a0,s4
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	b1c080e7          	jalr	-1252(ra) # 80003f72 <iunlockput>
  end_op();
    8000545e:	fffff097          	auipc	ra,0xfffff
    80005462:	2f6080e7          	jalr	758(ra) # 80004754 <end_op>
  p = myproc();
    80005466:	ffffc097          	auipc	ra,0xffffc
    8000546a:	5e4080e7          	jalr	1508(ra) # 80001a4a <myproc>
    8000546e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005470:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005474:	6985                	lui	s3,0x1
    80005476:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005478:	99ca                	add	s3,s3,s2
    8000547a:	77fd                	lui	a5,0xfffff
    8000547c:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005480:	4691                	li	a3,4
    80005482:	6609                	lui	a2,0x2
    80005484:	964e                	add	a2,a2,s3
    80005486:	85ce                	mv	a1,s3
    80005488:	855a                	mv	a0,s6
    8000548a:	ffffc097          	auipc	ra,0xffffc
    8000548e:	ff0080e7          	jalr	-16(ra) # 8000147a <uvmalloc>
    80005492:	892a                	mv	s2,a0
    80005494:	e0a43423          	sd	a0,-504(s0)
    80005498:	e519                	bnez	a0,800054a6 <exec+0x22c>
  if(pagetable)
    8000549a:	e1343423          	sd	s3,-504(s0)
    8000549e:	4a01                	li	s4,0
    800054a0:	aaa5                	j	80005618 <exec+0x39e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800054a2:	4901                	li	s2,0
    800054a4:	bf45                	j	80005454 <exec+0x1da>
  uvmclear(pagetable, sz-2*PGSIZE);
    800054a6:	75f9                	lui	a1,0xffffe
    800054a8:	95aa                	add	a1,a1,a0
    800054aa:	855a                	mv	a0,s6
    800054ac:	ffffc097          	auipc	ra,0xffffc
    800054b0:	204080e7          	jalr	516(ra) # 800016b0 <uvmclear>
  stackbase = sp - PGSIZE;
    800054b4:	7bfd                	lui	s7,0xfffff
    800054b6:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800054b8:	e0043783          	ld	a5,-512(s0)
    800054bc:	6388                	ld	a0,0(a5)
    800054be:	c52d                	beqz	a0,80005528 <exec+0x2ae>
    800054c0:	e9040993          	addi	s3,s0,-368
    800054c4:	f9040c13          	addi	s8,s0,-112
    800054c8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800054ca:	ffffc097          	auipc	ra,0xffffc
    800054ce:	9de080e7          	jalr	-1570(ra) # 80000ea8 <strlen>
    800054d2:	0015079b          	addiw	a5,a0,1
    800054d6:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054da:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800054de:	13796863          	bltu	s2,s7,8000560e <exec+0x394>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054e2:	e0043d03          	ld	s10,-512(s0)
    800054e6:	000d3a03          	ld	s4,0(s10)
    800054ea:	8552                	mv	a0,s4
    800054ec:	ffffc097          	auipc	ra,0xffffc
    800054f0:	9bc080e7          	jalr	-1604(ra) # 80000ea8 <strlen>
    800054f4:	0015069b          	addiw	a3,a0,1
    800054f8:	8652                	mv	a2,s4
    800054fa:	85ca                	mv	a1,s2
    800054fc:	855a                	mv	a0,s6
    800054fe:	ffffc097          	auipc	ra,0xffffc
    80005502:	1e4080e7          	jalr	484(ra) # 800016e2 <copyout>
    80005506:	10054663          	bltz	a0,80005612 <exec+0x398>
    ustack[argc] = sp;
    8000550a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000550e:	0485                	addi	s1,s1,1
    80005510:	008d0793          	addi	a5,s10,8
    80005514:	e0f43023          	sd	a5,-512(s0)
    80005518:	008d3503          	ld	a0,8(s10)
    8000551c:	c909                	beqz	a0,8000552e <exec+0x2b4>
    if(argc >= MAXARG)
    8000551e:	09a1                	addi	s3,s3,8
    80005520:	fb8995e3          	bne	s3,s8,800054ca <exec+0x250>
  ip = 0;
    80005524:	4a01                	li	s4,0
    80005526:	a8cd                	j	80005618 <exec+0x39e>
  sp = sz;
    80005528:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    8000552c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000552e:	00349793          	slli	a5,s1,0x3
    80005532:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd7960>
    80005536:	97a2                	add	a5,a5,s0
    80005538:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000553c:	00148693          	addi	a3,s1,1
    80005540:	068e                	slli	a3,a3,0x3
    80005542:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005546:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    8000554a:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    8000554e:	f57966e3          	bltu	s2,s7,8000549a <exec+0x220>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005552:	e9040613          	addi	a2,s0,-368
    80005556:	85ca                	mv	a1,s2
    80005558:	855a                	mv	a0,s6
    8000555a:	ffffc097          	auipc	ra,0xffffc
    8000555e:	188080e7          	jalr	392(ra) # 800016e2 <copyout>
    80005562:	0e054863          	bltz	a0,80005652 <exec+0x3d8>
  p->trapframe->a1 = sp;
    80005566:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    8000556a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000556e:	df843783          	ld	a5,-520(s0)
    80005572:	0007c703          	lbu	a4,0(a5)
    80005576:	cf11                	beqz	a4,80005592 <exec+0x318>
    80005578:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000557a:	02f00693          	li	a3,47
    8000557e:	a039                	j	8000558c <exec+0x312>
      last = s+1;
    80005580:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005584:	0785                	addi	a5,a5,1
    80005586:	fff7c703          	lbu	a4,-1(a5)
    8000558a:	c701                	beqz	a4,80005592 <exec+0x318>
    if(*s == '/')
    8000558c:	fed71ce3          	bne	a4,a3,80005584 <exec+0x30a>
    80005590:	bfc5                	j	80005580 <exec+0x306>
  safestrcpy(p->name, last, sizeof(p->name));
    80005592:	4641                	li	a2,16
    80005594:	df843583          	ld	a1,-520(s0)
    80005598:	158a8513          	addi	a0,s5,344
    8000559c:	ffffc097          	auipc	ra,0xffffc
    800055a0:	8da080e7          	jalr	-1830(ra) # 80000e76 <safestrcpy>
  oldpagetable = p->pagetable;
    800055a4:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800055a8:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800055ac:	e0843783          	ld	a5,-504(s0)
    800055b0:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055b4:	058ab783          	ld	a5,88(s5)
    800055b8:	e6843703          	ld	a4,-408(s0)
    800055bc:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055be:	058ab783          	ld	a5,88(s5)
    800055c2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800055c6:	85e6                	mv	a1,s9
    800055c8:	ffffc097          	auipc	ra,0xffffc
    800055cc:	5e2080e7          	jalr	1506(ra) # 80001baa <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055d0:	0004851b          	sext.w	a0,s1
    800055d4:	79be                	ld	s3,488(sp)
    800055d6:	7a1e                	ld	s4,480(sp)
    800055d8:	6afe                	ld	s5,472(sp)
    800055da:	6b5e                	ld	s6,464(sp)
    800055dc:	6bbe                	ld	s7,456(sp)
    800055de:	6c1e                	ld	s8,448(sp)
    800055e0:	7cfa                	ld	s9,440(sp)
    800055e2:	7d5a                	ld	s10,432(sp)
    800055e4:	b305                	j	80005304 <exec+0x8a>
    800055e6:	e1243423          	sd	s2,-504(s0)
    800055ea:	7dba                	ld	s11,424(sp)
    800055ec:	a035                	j	80005618 <exec+0x39e>
    800055ee:	e1243423          	sd	s2,-504(s0)
    800055f2:	7dba                	ld	s11,424(sp)
    800055f4:	a015                	j	80005618 <exec+0x39e>
    800055f6:	e1243423          	sd	s2,-504(s0)
    800055fa:	7dba                	ld	s11,424(sp)
    800055fc:	a831                	j	80005618 <exec+0x39e>
    800055fe:	e1243423          	sd	s2,-504(s0)
    80005602:	7dba                	ld	s11,424(sp)
    80005604:	a811                	j	80005618 <exec+0x39e>
    80005606:	e1243423          	sd	s2,-504(s0)
    8000560a:	7dba                	ld	s11,424(sp)
    8000560c:	a031                	j	80005618 <exec+0x39e>
  ip = 0;
    8000560e:	4a01                	li	s4,0
    80005610:	a021                	j	80005618 <exec+0x39e>
    80005612:	4a01                	li	s4,0
  if(pagetable)
    80005614:	a011                	j	80005618 <exec+0x39e>
    80005616:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    80005618:	e0843583          	ld	a1,-504(s0)
    8000561c:	855a                	mv	a0,s6
    8000561e:	ffffc097          	auipc	ra,0xffffc
    80005622:	58c080e7          	jalr	1420(ra) # 80001baa <proc_freepagetable>
  return -1;
    80005626:	557d                	li	a0,-1
  if(ip){
    80005628:	000a1b63          	bnez	s4,8000563e <exec+0x3c4>
    8000562c:	79be                	ld	s3,488(sp)
    8000562e:	7a1e                	ld	s4,480(sp)
    80005630:	6afe                	ld	s5,472(sp)
    80005632:	6b5e                	ld	s6,464(sp)
    80005634:	6bbe                	ld	s7,456(sp)
    80005636:	6c1e                	ld	s8,448(sp)
    80005638:	7cfa                	ld	s9,440(sp)
    8000563a:	7d5a                	ld	s10,432(sp)
    8000563c:	b1e1                	j	80005304 <exec+0x8a>
    8000563e:	79be                	ld	s3,488(sp)
    80005640:	6afe                	ld	s5,472(sp)
    80005642:	6b5e                	ld	s6,464(sp)
    80005644:	6bbe                	ld	s7,456(sp)
    80005646:	6c1e                	ld	s8,448(sp)
    80005648:	7cfa                	ld	s9,440(sp)
    8000564a:	7d5a                	ld	s10,432(sp)
    8000564c:	b14d                	j	800052ee <exec+0x74>
    8000564e:	6b5e                	ld	s6,464(sp)
    80005650:	b979                	j	800052ee <exec+0x74>
  sz = sz1;
    80005652:	e0843983          	ld	s3,-504(s0)
    80005656:	b591                	j	8000549a <exec+0x220>

0000000080005658 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005658:	7179                	addi	sp,sp,-48
    8000565a:	f406                	sd	ra,40(sp)
    8000565c:	f022                	sd	s0,32(sp)
    8000565e:	ec26                	sd	s1,24(sp)
    80005660:	e84a                	sd	s2,16(sp)
    80005662:	1800                	addi	s0,sp,48
    80005664:	892e                	mv	s2,a1
    80005666:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005668:	fdc40593          	addi	a1,s0,-36
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	96e080e7          	jalr	-1682(ra) # 80002fda <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005674:	fdc42703          	lw	a4,-36(s0)
    80005678:	47bd                	li	a5,15
    8000567a:	02e7eb63          	bltu	a5,a4,800056b0 <argfd+0x58>
    8000567e:	ffffc097          	auipc	ra,0xffffc
    80005682:	3cc080e7          	jalr	972(ra) # 80001a4a <myproc>
    80005686:	fdc42703          	lw	a4,-36(s0)
    8000568a:	01a70793          	addi	a5,a4,26
    8000568e:	078e                	slli	a5,a5,0x3
    80005690:	953e                	add	a0,a0,a5
    80005692:	611c                	ld	a5,0(a0)
    80005694:	c385                	beqz	a5,800056b4 <argfd+0x5c>
    return -1;
  if(pfd)
    80005696:	00090463          	beqz	s2,8000569e <argfd+0x46>
    *pfd = fd;
    8000569a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000569e:	4501                	li	a0,0
  if(pf)
    800056a0:	c091                	beqz	s1,800056a4 <argfd+0x4c>
    *pf = f;
    800056a2:	e09c                	sd	a5,0(s1)
}
    800056a4:	70a2                	ld	ra,40(sp)
    800056a6:	7402                	ld	s0,32(sp)
    800056a8:	64e2                	ld	s1,24(sp)
    800056aa:	6942                	ld	s2,16(sp)
    800056ac:	6145                	addi	sp,sp,48
    800056ae:	8082                	ret
    return -1;
    800056b0:	557d                	li	a0,-1
    800056b2:	bfcd                	j	800056a4 <argfd+0x4c>
    800056b4:	557d                	li	a0,-1
    800056b6:	b7fd                	j	800056a4 <argfd+0x4c>

00000000800056b8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056b8:	1101                	addi	sp,sp,-32
    800056ba:	ec06                	sd	ra,24(sp)
    800056bc:	e822                	sd	s0,16(sp)
    800056be:	e426                	sd	s1,8(sp)
    800056c0:	1000                	addi	s0,sp,32
    800056c2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056c4:	ffffc097          	auipc	ra,0xffffc
    800056c8:	386080e7          	jalr	902(ra) # 80001a4a <myproc>
    800056cc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800056ce:	0d050793          	addi	a5,a0,208
    800056d2:	4501                	li	a0,0
    800056d4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056d6:	6398                	ld	a4,0(a5)
    800056d8:	cb19                	beqz	a4,800056ee <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800056da:	2505                	addiw	a0,a0,1
    800056dc:	07a1                	addi	a5,a5,8
    800056de:	fed51ce3          	bne	a0,a3,800056d6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800056e2:	557d                	li	a0,-1
}
    800056e4:	60e2                	ld	ra,24(sp)
    800056e6:	6442                	ld	s0,16(sp)
    800056e8:	64a2                	ld	s1,8(sp)
    800056ea:	6105                	addi	sp,sp,32
    800056ec:	8082                	ret
      p->ofile[fd] = f;
    800056ee:	01a50793          	addi	a5,a0,26
    800056f2:	078e                	slli	a5,a5,0x3
    800056f4:	963e                	add	a2,a2,a5
    800056f6:	e204                	sd	s1,0(a2)
      return fd;
    800056f8:	b7f5                	j	800056e4 <fdalloc+0x2c>

00000000800056fa <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800056fa:	715d                	addi	sp,sp,-80
    800056fc:	e486                	sd	ra,72(sp)
    800056fe:	e0a2                	sd	s0,64(sp)
    80005700:	fc26                	sd	s1,56(sp)
    80005702:	f84a                	sd	s2,48(sp)
    80005704:	f44e                	sd	s3,40(sp)
    80005706:	ec56                	sd	s5,24(sp)
    80005708:	e85a                	sd	s6,16(sp)
    8000570a:	0880                	addi	s0,sp,80
    8000570c:	8b2e                	mv	s6,a1
    8000570e:	89b2                	mv	s3,a2
    80005710:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005712:	fb040593          	addi	a1,s0,-80
    80005716:	fffff097          	auipc	ra,0xfffff
    8000571a:	de2080e7          	jalr	-542(ra) # 800044f8 <nameiparent>
    8000571e:	84aa                	mv	s1,a0
    80005720:	14050e63          	beqz	a0,8000587c <create+0x182>
    return 0;

  ilock(dp);
    80005724:	ffffe097          	auipc	ra,0xffffe
    80005728:	5e8080e7          	jalr	1512(ra) # 80003d0c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000572c:	4601                	li	a2,0
    8000572e:	fb040593          	addi	a1,s0,-80
    80005732:	8526                	mv	a0,s1
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	ae4080e7          	jalr	-1308(ra) # 80004218 <dirlookup>
    8000573c:	8aaa                	mv	s5,a0
    8000573e:	c539                	beqz	a0,8000578c <create+0x92>
    iunlockput(dp);
    80005740:	8526                	mv	a0,s1
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	830080e7          	jalr	-2000(ra) # 80003f72 <iunlockput>
    ilock(ip);
    8000574a:	8556                	mv	a0,s5
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	5c0080e7          	jalr	1472(ra) # 80003d0c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005754:	4789                	li	a5,2
    80005756:	02fb1463          	bne	s6,a5,8000577e <create+0x84>
    8000575a:	044ad783          	lhu	a5,68(s5)
    8000575e:	37f9                	addiw	a5,a5,-2
    80005760:	17c2                	slli	a5,a5,0x30
    80005762:	93c1                	srli	a5,a5,0x30
    80005764:	4705                	li	a4,1
    80005766:	00f76c63          	bltu	a4,a5,8000577e <create+0x84>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000576a:	8556                	mv	a0,s5
    8000576c:	60a6                	ld	ra,72(sp)
    8000576e:	6406                	ld	s0,64(sp)
    80005770:	74e2                	ld	s1,56(sp)
    80005772:	7942                	ld	s2,48(sp)
    80005774:	79a2                	ld	s3,40(sp)
    80005776:	6ae2                	ld	s5,24(sp)
    80005778:	6b42                	ld	s6,16(sp)
    8000577a:	6161                	addi	sp,sp,80
    8000577c:	8082                	ret
    iunlockput(ip);
    8000577e:	8556                	mv	a0,s5
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	7f2080e7          	jalr	2034(ra) # 80003f72 <iunlockput>
    return 0;
    80005788:	4a81                	li	s5,0
    8000578a:	b7c5                	j	8000576a <create+0x70>
    8000578c:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    8000578e:	85da                	mv	a1,s6
    80005790:	4088                	lw	a0,0(s1)
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	3d6080e7          	jalr	982(ra) # 80003b68 <ialloc>
    8000579a:	8a2a                	mv	s4,a0
    8000579c:	c531                	beqz	a0,800057e8 <create+0xee>
  ilock(ip);
    8000579e:	ffffe097          	auipc	ra,0xffffe
    800057a2:	56e080e7          	jalr	1390(ra) # 80003d0c <ilock>
  ip->major = major;
    800057a6:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800057aa:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800057ae:	4905                	li	s2,1
    800057b0:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800057b4:	8552                	mv	a0,s4
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	48a080e7          	jalr	1162(ra) # 80003c40 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800057be:	032b0d63          	beq	s6,s2,800057f8 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800057c2:	004a2603          	lw	a2,4(s4)
    800057c6:	fb040593          	addi	a1,s0,-80
    800057ca:	8526                	mv	a0,s1
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	c5c080e7          	jalr	-932(ra) # 80004428 <dirlink>
    800057d4:	08054163          	bltz	a0,80005856 <create+0x15c>
  iunlockput(dp);
    800057d8:	8526                	mv	a0,s1
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	798080e7          	jalr	1944(ra) # 80003f72 <iunlockput>
  return ip;
    800057e2:	8ad2                	mv	s5,s4
    800057e4:	7a02                	ld	s4,32(sp)
    800057e6:	b751                	j	8000576a <create+0x70>
    iunlockput(dp);
    800057e8:	8526                	mv	a0,s1
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	788080e7          	jalr	1928(ra) # 80003f72 <iunlockput>
    return 0;
    800057f2:	8ad2                	mv	s5,s4
    800057f4:	7a02                	ld	s4,32(sp)
    800057f6:	bf95                	j	8000576a <create+0x70>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800057f8:	004a2603          	lw	a2,4(s4)
    800057fc:	00003597          	auipc	a1,0x3
    80005800:	df458593          	addi	a1,a1,-524 # 800085f0 <etext+0x5f0>
    80005804:	8552                	mv	a0,s4
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	c22080e7          	jalr	-990(ra) # 80004428 <dirlink>
    8000580e:	04054463          	bltz	a0,80005856 <create+0x15c>
    80005812:	40d0                	lw	a2,4(s1)
    80005814:	00003597          	auipc	a1,0x3
    80005818:	de458593          	addi	a1,a1,-540 # 800085f8 <etext+0x5f8>
    8000581c:	8552                	mv	a0,s4
    8000581e:	fffff097          	auipc	ra,0xfffff
    80005822:	c0a080e7          	jalr	-1014(ra) # 80004428 <dirlink>
    80005826:	02054863          	bltz	a0,80005856 <create+0x15c>
  if(dirlink(dp, name, ip->inum) < 0)
    8000582a:	004a2603          	lw	a2,4(s4)
    8000582e:	fb040593          	addi	a1,s0,-80
    80005832:	8526                	mv	a0,s1
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	bf4080e7          	jalr	-1036(ra) # 80004428 <dirlink>
    8000583c:	00054d63          	bltz	a0,80005856 <create+0x15c>
    dp->nlink++;  // for ".."
    80005840:	04a4d783          	lhu	a5,74(s1)
    80005844:	2785                	addiw	a5,a5,1
    80005846:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000584a:	8526                	mv	a0,s1
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	3f4080e7          	jalr	1012(ra) # 80003c40 <iupdate>
    80005854:	b751                	j	800057d8 <create+0xde>
  ip->nlink = 0;
    80005856:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000585a:	8552                	mv	a0,s4
    8000585c:	ffffe097          	auipc	ra,0xffffe
    80005860:	3e4080e7          	jalr	996(ra) # 80003c40 <iupdate>
  iunlockput(ip);
    80005864:	8552                	mv	a0,s4
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	70c080e7          	jalr	1804(ra) # 80003f72 <iunlockput>
  iunlockput(dp);
    8000586e:	8526                	mv	a0,s1
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	702080e7          	jalr	1794(ra) # 80003f72 <iunlockput>
  return 0;
    80005878:	7a02                	ld	s4,32(sp)
    8000587a:	bdc5                	j	8000576a <create+0x70>
    return 0;
    8000587c:	8aaa                	mv	s5,a0
    8000587e:	b5f5                	j	8000576a <create+0x70>

0000000080005880 <sys_dup>:
{
    80005880:	7179                	addi	sp,sp,-48
    80005882:	f406                	sd	ra,40(sp)
    80005884:	f022                	sd	s0,32(sp)
    80005886:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005888:	fd840613          	addi	a2,s0,-40
    8000588c:	4581                	li	a1,0
    8000588e:	4501                	li	a0,0
    80005890:	00000097          	auipc	ra,0x0
    80005894:	dc8080e7          	jalr	-568(ra) # 80005658 <argfd>
    return -1;
    80005898:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000589a:	02054763          	bltz	a0,800058c8 <sys_dup+0x48>
    8000589e:	ec26                	sd	s1,24(sp)
    800058a0:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    800058a2:	fd843903          	ld	s2,-40(s0)
    800058a6:	854a                	mv	a0,s2
    800058a8:	00000097          	auipc	ra,0x0
    800058ac:	e10080e7          	jalr	-496(ra) # 800056b8 <fdalloc>
    800058b0:	84aa                	mv	s1,a0
    return -1;
    800058b2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800058b4:	00054f63          	bltz	a0,800058d2 <sys_dup+0x52>
  filedup(f);
    800058b8:	854a                	mv	a0,s2
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	298080e7          	jalr	664(ra) # 80004b52 <filedup>
  return fd;
    800058c2:	87a6                	mv	a5,s1
    800058c4:	64e2                	ld	s1,24(sp)
    800058c6:	6942                	ld	s2,16(sp)
}
    800058c8:	853e                	mv	a0,a5
    800058ca:	70a2                	ld	ra,40(sp)
    800058cc:	7402                	ld	s0,32(sp)
    800058ce:	6145                	addi	sp,sp,48
    800058d0:	8082                	ret
    800058d2:	64e2                	ld	s1,24(sp)
    800058d4:	6942                	ld	s2,16(sp)
    800058d6:	bfcd                	j	800058c8 <sys_dup+0x48>

00000000800058d8 <sys_read>:
{
    800058d8:	7179                	addi	sp,sp,-48
    800058da:	f406                	sd	ra,40(sp)
    800058dc:	f022                	sd	s0,32(sp)
    800058de:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800058e0:	fd840593          	addi	a1,s0,-40
    800058e4:	4505                	li	a0,1
    800058e6:	ffffd097          	auipc	ra,0xffffd
    800058ea:	714080e7          	jalr	1812(ra) # 80002ffa <argaddr>
  argint(2, &n);
    800058ee:	fe440593          	addi	a1,s0,-28
    800058f2:	4509                	li	a0,2
    800058f4:	ffffd097          	auipc	ra,0xffffd
    800058f8:	6e6080e7          	jalr	1766(ra) # 80002fda <argint>
  if(argfd(0, 0, &f) < 0)
    800058fc:	fe840613          	addi	a2,s0,-24
    80005900:	4581                	li	a1,0
    80005902:	4501                	li	a0,0
    80005904:	00000097          	auipc	ra,0x0
    80005908:	d54080e7          	jalr	-684(ra) # 80005658 <argfd>
    8000590c:	87aa                	mv	a5,a0
    return -1;
    8000590e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005910:	0007cc63          	bltz	a5,80005928 <sys_read+0x50>
  return fileread(f, p, n);
    80005914:	fe442603          	lw	a2,-28(s0)
    80005918:	fd843583          	ld	a1,-40(s0)
    8000591c:	fe843503          	ld	a0,-24(s0)
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	3d8080e7          	jalr	984(ra) # 80004cf8 <fileread>
}
    80005928:	70a2                	ld	ra,40(sp)
    8000592a:	7402                	ld	s0,32(sp)
    8000592c:	6145                	addi	sp,sp,48
    8000592e:	8082                	ret

0000000080005930 <sys_write>:
{
    80005930:	7179                	addi	sp,sp,-48
    80005932:	f406                	sd	ra,40(sp)
    80005934:	f022                	sd	s0,32(sp)
    80005936:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005938:	fd840593          	addi	a1,s0,-40
    8000593c:	4505                	li	a0,1
    8000593e:	ffffd097          	auipc	ra,0xffffd
    80005942:	6bc080e7          	jalr	1724(ra) # 80002ffa <argaddr>
  argint(2, &n);
    80005946:	fe440593          	addi	a1,s0,-28
    8000594a:	4509                	li	a0,2
    8000594c:	ffffd097          	auipc	ra,0xffffd
    80005950:	68e080e7          	jalr	1678(ra) # 80002fda <argint>
  if(argfd(0, 0, &f) < 0)
    80005954:	fe840613          	addi	a2,s0,-24
    80005958:	4581                	li	a1,0
    8000595a:	4501                	li	a0,0
    8000595c:	00000097          	auipc	ra,0x0
    80005960:	cfc080e7          	jalr	-772(ra) # 80005658 <argfd>
    80005964:	87aa                	mv	a5,a0
    return -1;
    80005966:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005968:	0007cc63          	bltz	a5,80005980 <sys_write+0x50>
  return filewrite(f, p, n);
    8000596c:	fe442603          	lw	a2,-28(s0)
    80005970:	fd843583          	ld	a1,-40(s0)
    80005974:	fe843503          	ld	a0,-24(s0)
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	452080e7          	jalr	1106(ra) # 80004dca <filewrite>
}
    80005980:	70a2                	ld	ra,40(sp)
    80005982:	7402                	ld	s0,32(sp)
    80005984:	6145                	addi	sp,sp,48
    80005986:	8082                	ret

0000000080005988 <sys_close>:
{
    80005988:	1101                	addi	sp,sp,-32
    8000598a:	ec06                	sd	ra,24(sp)
    8000598c:	e822                	sd	s0,16(sp)
    8000598e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005990:	fe040613          	addi	a2,s0,-32
    80005994:	fec40593          	addi	a1,s0,-20
    80005998:	4501                	li	a0,0
    8000599a:	00000097          	auipc	ra,0x0
    8000599e:	cbe080e7          	jalr	-834(ra) # 80005658 <argfd>
    return -1;
    800059a2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800059a4:	02054463          	bltz	a0,800059cc <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059a8:	ffffc097          	auipc	ra,0xffffc
    800059ac:	0a2080e7          	jalr	162(ra) # 80001a4a <myproc>
    800059b0:	fec42783          	lw	a5,-20(s0)
    800059b4:	07e9                	addi	a5,a5,26
    800059b6:	078e                	slli	a5,a5,0x3
    800059b8:	953e                	add	a0,a0,a5
    800059ba:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800059be:	fe043503          	ld	a0,-32(s0)
    800059c2:	fffff097          	auipc	ra,0xfffff
    800059c6:	1e2080e7          	jalr	482(ra) # 80004ba4 <fileclose>
  return 0;
    800059ca:	4781                	li	a5,0
}
    800059cc:	853e                	mv	a0,a5
    800059ce:	60e2                	ld	ra,24(sp)
    800059d0:	6442                	ld	s0,16(sp)
    800059d2:	6105                	addi	sp,sp,32
    800059d4:	8082                	ret

00000000800059d6 <sys_fstat>:
{
    800059d6:	1101                	addi	sp,sp,-32
    800059d8:	ec06                	sd	ra,24(sp)
    800059da:	e822                	sd	s0,16(sp)
    800059dc:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800059de:	fe040593          	addi	a1,s0,-32
    800059e2:	4505                	li	a0,1
    800059e4:	ffffd097          	auipc	ra,0xffffd
    800059e8:	616080e7          	jalr	1558(ra) # 80002ffa <argaddr>
  if(argfd(0, 0, &f) < 0)
    800059ec:	fe840613          	addi	a2,s0,-24
    800059f0:	4581                	li	a1,0
    800059f2:	4501                	li	a0,0
    800059f4:	00000097          	auipc	ra,0x0
    800059f8:	c64080e7          	jalr	-924(ra) # 80005658 <argfd>
    800059fc:	87aa                	mv	a5,a0
    return -1;
    800059fe:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a00:	0007ca63          	bltz	a5,80005a14 <sys_fstat+0x3e>
  return filestat(f, st);
    80005a04:	fe043583          	ld	a1,-32(s0)
    80005a08:	fe843503          	ld	a0,-24(s0)
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	27a080e7          	jalr	634(ra) # 80004c86 <filestat>
}
    80005a14:	60e2                	ld	ra,24(sp)
    80005a16:	6442                	ld	s0,16(sp)
    80005a18:	6105                	addi	sp,sp,32
    80005a1a:	8082                	ret

0000000080005a1c <sys_link>:
{
    80005a1c:	7169                	addi	sp,sp,-304
    80005a1e:	f606                	sd	ra,296(sp)
    80005a20:	f222                	sd	s0,288(sp)
    80005a22:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a24:	08000613          	li	a2,128
    80005a28:	ed040593          	addi	a1,s0,-304
    80005a2c:	4501                	li	a0,0
    80005a2e:	ffffd097          	auipc	ra,0xffffd
    80005a32:	5ec080e7          	jalr	1516(ra) # 8000301a <argstr>
    return -1;
    80005a36:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a38:	12054663          	bltz	a0,80005b64 <sys_link+0x148>
    80005a3c:	08000613          	li	a2,128
    80005a40:	f5040593          	addi	a1,s0,-176
    80005a44:	4505                	li	a0,1
    80005a46:	ffffd097          	auipc	ra,0xffffd
    80005a4a:	5d4080e7          	jalr	1492(ra) # 8000301a <argstr>
    return -1;
    80005a4e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a50:	10054a63          	bltz	a0,80005b64 <sys_link+0x148>
    80005a54:	ee26                	sd	s1,280(sp)
  begin_op();
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	c84080e7          	jalr	-892(ra) # 800046da <begin_op>
  if((ip = namei(old)) == 0){
    80005a5e:	ed040513          	addi	a0,s0,-304
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	a78080e7          	jalr	-1416(ra) # 800044da <namei>
    80005a6a:	84aa                	mv	s1,a0
    80005a6c:	c949                	beqz	a0,80005afe <sys_link+0xe2>
  ilock(ip);
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	29e080e7          	jalr	670(ra) # 80003d0c <ilock>
  if(ip->type == T_DIR){
    80005a76:	04449703          	lh	a4,68(s1)
    80005a7a:	4785                	li	a5,1
    80005a7c:	08f70863          	beq	a4,a5,80005b0c <sys_link+0xf0>
    80005a80:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80005a82:	04a4d783          	lhu	a5,74(s1)
    80005a86:	2785                	addiw	a5,a5,1
    80005a88:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a8c:	8526                	mv	a0,s1
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	1b2080e7          	jalr	434(ra) # 80003c40 <iupdate>
  iunlock(ip);
    80005a96:	8526                	mv	a0,s1
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	33a080e7          	jalr	826(ra) # 80003dd2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005aa0:	fd040593          	addi	a1,s0,-48
    80005aa4:	f5040513          	addi	a0,s0,-176
    80005aa8:	fffff097          	auipc	ra,0xfffff
    80005aac:	a50080e7          	jalr	-1456(ra) # 800044f8 <nameiparent>
    80005ab0:	892a                	mv	s2,a0
    80005ab2:	cd35                	beqz	a0,80005b2e <sys_link+0x112>
  ilock(dp);
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	258080e7          	jalr	600(ra) # 80003d0c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005abc:	00092703          	lw	a4,0(s2)
    80005ac0:	409c                	lw	a5,0(s1)
    80005ac2:	06f71163          	bne	a4,a5,80005b24 <sys_link+0x108>
    80005ac6:	40d0                	lw	a2,4(s1)
    80005ac8:	fd040593          	addi	a1,s0,-48
    80005acc:	854a                	mv	a0,s2
    80005ace:	fffff097          	auipc	ra,0xfffff
    80005ad2:	95a080e7          	jalr	-1702(ra) # 80004428 <dirlink>
    80005ad6:	04054763          	bltz	a0,80005b24 <sys_link+0x108>
  iunlockput(dp);
    80005ada:	854a                	mv	a0,s2
    80005adc:	ffffe097          	auipc	ra,0xffffe
    80005ae0:	496080e7          	jalr	1174(ra) # 80003f72 <iunlockput>
  iput(ip);
    80005ae4:	8526                	mv	a0,s1
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	3e4080e7          	jalr	996(ra) # 80003eca <iput>
  end_op();
    80005aee:	fffff097          	auipc	ra,0xfffff
    80005af2:	c66080e7          	jalr	-922(ra) # 80004754 <end_op>
  return 0;
    80005af6:	4781                	li	a5,0
    80005af8:	64f2                	ld	s1,280(sp)
    80005afa:	6952                	ld	s2,272(sp)
    80005afc:	a0a5                	j	80005b64 <sys_link+0x148>
    end_op();
    80005afe:	fffff097          	auipc	ra,0xfffff
    80005b02:	c56080e7          	jalr	-938(ra) # 80004754 <end_op>
    return -1;
    80005b06:	57fd                	li	a5,-1
    80005b08:	64f2                	ld	s1,280(sp)
    80005b0a:	a8a9                	j	80005b64 <sys_link+0x148>
    iunlockput(ip);
    80005b0c:	8526                	mv	a0,s1
    80005b0e:	ffffe097          	auipc	ra,0xffffe
    80005b12:	464080e7          	jalr	1124(ra) # 80003f72 <iunlockput>
    end_op();
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	c3e080e7          	jalr	-962(ra) # 80004754 <end_op>
    return -1;
    80005b1e:	57fd                	li	a5,-1
    80005b20:	64f2                	ld	s1,280(sp)
    80005b22:	a089                	j	80005b64 <sys_link+0x148>
    iunlockput(dp);
    80005b24:	854a                	mv	a0,s2
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	44c080e7          	jalr	1100(ra) # 80003f72 <iunlockput>
  ilock(ip);
    80005b2e:	8526                	mv	a0,s1
    80005b30:	ffffe097          	auipc	ra,0xffffe
    80005b34:	1dc080e7          	jalr	476(ra) # 80003d0c <ilock>
  ip->nlink--;
    80005b38:	04a4d783          	lhu	a5,74(s1)
    80005b3c:	37fd                	addiw	a5,a5,-1
    80005b3e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b42:	8526                	mv	a0,s1
    80005b44:	ffffe097          	auipc	ra,0xffffe
    80005b48:	0fc080e7          	jalr	252(ra) # 80003c40 <iupdate>
  iunlockput(ip);
    80005b4c:	8526                	mv	a0,s1
    80005b4e:	ffffe097          	auipc	ra,0xffffe
    80005b52:	424080e7          	jalr	1060(ra) # 80003f72 <iunlockput>
  end_op();
    80005b56:	fffff097          	auipc	ra,0xfffff
    80005b5a:	bfe080e7          	jalr	-1026(ra) # 80004754 <end_op>
  return -1;
    80005b5e:	57fd                	li	a5,-1
    80005b60:	64f2                	ld	s1,280(sp)
    80005b62:	6952                	ld	s2,272(sp)
}
    80005b64:	853e                	mv	a0,a5
    80005b66:	70b2                	ld	ra,296(sp)
    80005b68:	7412                	ld	s0,288(sp)
    80005b6a:	6155                	addi	sp,sp,304
    80005b6c:	8082                	ret

0000000080005b6e <sys_unlink>:
{
    80005b6e:	7151                	addi	sp,sp,-240
    80005b70:	f586                	sd	ra,232(sp)
    80005b72:	f1a2                	sd	s0,224(sp)
    80005b74:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b76:	08000613          	li	a2,128
    80005b7a:	f3040593          	addi	a1,s0,-208
    80005b7e:	4501                	li	a0,0
    80005b80:	ffffd097          	auipc	ra,0xffffd
    80005b84:	49a080e7          	jalr	1178(ra) # 8000301a <argstr>
    80005b88:	1a054a63          	bltz	a0,80005d3c <sys_unlink+0x1ce>
    80005b8c:	eda6                	sd	s1,216(sp)
  begin_op();
    80005b8e:	fffff097          	auipc	ra,0xfffff
    80005b92:	b4c080e7          	jalr	-1204(ra) # 800046da <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b96:	fb040593          	addi	a1,s0,-80
    80005b9a:	f3040513          	addi	a0,s0,-208
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	95a080e7          	jalr	-1702(ra) # 800044f8 <nameiparent>
    80005ba6:	84aa                	mv	s1,a0
    80005ba8:	cd71                	beqz	a0,80005c84 <sys_unlink+0x116>
  ilock(dp);
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	162080e7          	jalr	354(ra) # 80003d0c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bb2:	00003597          	auipc	a1,0x3
    80005bb6:	a3e58593          	addi	a1,a1,-1474 # 800085f0 <etext+0x5f0>
    80005bba:	fb040513          	addi	a0,s0,-80
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	640080e7          	jalr	1600(ra) # 800041fe <namecmp>
    80005bc6:	14050c63          	beqz	a0,80005d1e <sys_unlink+0x1b0>
    80005bca:	00003597          	auipc	a1,0x3
    80005bce:	a2e58593          	addi	a1,a1,-1490 # 800085f8 <etext+0x5f8>
    80005bd2:	fb040513          	addi	a0,s0,-80
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	628080e7          	jalr	1576(ra) # 800041fe <namecmp>
    80005bde:	14050063          	beqz	a0,80005d1e <sys_unlink+0x1b0>
    80005be2:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005be4:	f2c40613          	addi	a2,s0,-212
    80005be8:	fb040593          	addi	a1,s0,-80
    80005bec:	8526                	mv	a0,s1
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	62a080e7          	jalr	1578(ra) # 80004218 <dirlookup>
    80005bf6:	892a                	mv	s2,a0
    80005bf8:	12050263          	beqz	a0,80005d1c <sys_unlink+0x1ae>
  ilock(ip);
    80005bfc:	ffffe097          	auipc	ra,0xffffe
    80005c00:	110080e7          	jalr	272(ra) # 80003d0c <ilock>
  if(ip->nlink < 1)
    80005c04:	04a91783          	lh	a5,74(s2)
    80005c08:	08f05563          	blez	a5,80005c92 <sys_unlink+0x124>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c0c:	04491703          	lh	a4,68(s2)
    80005c10:	4785                	li	a5,1
    80005c12:	08f70963          	beq	a4,a5,80005ca4 <sys_unlink+0x136>
  memset(&de, 0, sizeof(de));
    80005c16:	4641                	li	a2,16
    80005c18:	4581                	li	a1,0
    80005c1a:	fc040513          	addi	a0,s0,-64
    80005c1e:	ffffb097          	auipc	ra,0xffffb
    80005c22:	116080e7          	jalr	278(ra) # 80000d34 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c26:	4741                	li	a4,16
    80005c28:	f2c42683          	lw	a3,-212(s0)
    80005c2c:	fc040613          	addi	a2,s0,-64
    80005c30:	4581                	li	a1,0
    80005c32:	8526                	mv	a0,s1
    80005c34:	ffffe097          	auipc	ra,0xffffe
    80005c38:	4a0080e7          	jalr	1184(ra) # 800040d4 <writei>
    80005c3c:	47c1                	li	a5,16
    80005c3e:	0af51b63          	bne	a0,a5,80005cf4 <sys_unlink+0x186>
  if(ip->type == T_DIR){
    80005c42:	04491703          	lh	a4,68(s2)
    80005c46:	4785                	li	a5,1
    80005c48:	0af70f63          	beq	a4,a5,80005d06 <sys_unlink+0x198>
  iunlockput(dp);
    80005c4c:	8526                	mv	a0,s1
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	324080e7          	jalr	804(ra) # 80003f72 <iunlockput>
  ip->nlink--;
    80005c56:	04a95783          	lhu	a5,74(s2)
    80005c5a:	37fd                	addiw	a5,a5,-1
    80005c5c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c60:	854a                	mv	a0,s2
    80005c62:	ffffe097          	auipc	ra,0xffffe
    80005c66:	fde080e7          	jalr	-34(ra) # 80003c40 <iupdate>
  iunlockput(ip);
    80005c6a:	854a                	mv	a0,s2
    80005c6c:	ffffe097          	auipc	ra,0xffffe
    80005c70:	306080e7          	jalr	774(ra) # 80003f72 <iunlockput>
  end_op();
    80005c74:	fffff097          	auipc	ra,0xfffff
    80005c78:	ae0080e7          	jalr	-1312(ra) # 80004754 <end_op>
  return 0;
    80005c7c:	4501                	li	a0,0
    80005c7e:	64ee                	ld	s1,216(sp)
    80005c80:	694e                	ld	s2,208(sp)
    80005c82:	a84d                	j	80005d34 <sys_unlink+0x1c6>
    end_op();
    80005c84:	fffff097          	auipc	ra,0xfffff
    80005c88:	ad0080e7          	jalr	-1328(ra) # 80004754 <end_op>
    return -1;
    80005c8c:	557d                	li	a0,-1
    80005c8e:	64ee                	ld	s1,216(sp)
    80005c90:	a055                	j	80005d34 <sys_unlink+0x1c6>
    80005c92:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    80005c94:	00003517          	auipc	a0,0x3
    80005c98:	96c50513          	addi	a0,a0,-1684 # 80008600 <etext+0x600>
    80005c9c:	ffffb097          	auipc	ra,0xffffb
    80005ca0:	8c4080e7          	jalr	-1852(ra) # 80000560 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ca4:	04c92703          	lw	a4,76(s2)
    80005ca8:	02000793          	li	a5,32
    80005cac:	f6e7f5e3          	bgeu	a5,a4,80005c16 <sys_unlink+0xa8>
    80005cb0:	e5ce                	sd	s3,200(sp)
    80005cb2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cb6:	4741                	li	a4,16
    80005cb8:	86ce                	mv	a3,s3
    80005cba:	f1840613          	addi	a2,s0,-232
    80005cbe:	4581                	li	a1,0
    80005cc0:	854a                	mv	a0,s2
    80005cc2:	ffffe097          	auipc	ra,0xffffe
    80005cc6:	302080e7          	jalr	770(ra) # 80003fc4 <readi>
    80005cca:	47c1                	li	a5,16
    80005ccc:	00f51c63          	bne	a0,a5,80005ce4 <sys_unlink+0x176>
    if(de.inum != 0)
    80005cd0:	f1845783          	lhu	a5,-232(s0)
    80005cd4:	e7b5                	bnez	a5,80005d40 <sys_unlink+0x1d2>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cd6:	29c1                	addiw	s3,s3,16
    80005cd8:	04c92783          	lw	a5,76(s2)
    80005cdc:	fcf9ede3          	bltu	s3,a5,80005cb6 <sys_unlink+0x148>
    80005ce0:	69ae                	ld	s3,200(sp)
    80005ce2:	bf15                	j	80005c16 <sys_unlink+0xa8>
      panic("isdirempty: readi");
    80005ce4:	00003517          	auipc	a0,0x3
    80005ce8:	93450513          	addi	a0,a0,-1740 # 80008618 <etext+0x618>
    80005cec:	ffffb097          	auipc	ra,0xffffb
    80005cf0:	874080e7          	jalr	-1932(ra) # 80000560 <panic>
    80005cf4:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    80005cf6:	00003517          	auipc	a0,0x3
    80005cfa:	93a50513          	addi	a0,a0,-1734 # 80008630 <etext+0x630>
    80005cfe:	ffffb097          	auipc	ra,0xffffb
    80005d02:	862080e7          	jalr	-1950(ra) # 80000560 <panic>
    dp->nlink--;
    80005d06:	04a4d783          	lhu	a5,74(s1)
    80005d0a:	37fd                	addiw	a5,a5,-1
    80005d0c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d10:	8526                	mv	a0,s1
    80005d12:	ffffe097          	auipc	ra,0xffffe
    80005d16:	f2e080e7          	jalr	-210(ra) # 80003c40 <iupdate>
    80005d1a:	bf0d                	j	80005c4c <sys_unlink+0xde>
    80005d1c:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    80005d1e:	8526                	mv	a0,s1
    80005d20:	ffffe097          	auipc	ra,0xffffe
    80005d24:	252080e7          	jalr	594(ra) # 80003f72 <iunlockput>
  end_op();
    80005d28:	fffff097          	auipc	ra,0xfffff
    80005d2c:	a2c080e7          	jalr	-1492(ra) # 80004754 <end_op>
  return -1;
    80005d30:	557d                	li	a0,-1
    80005d32:	64ee                	ld	s1,216(sp)
}
    80005d34:	70ae                	ld	ra,232(sp)
    80005d36:	740e                	ld	s0,224(sp)
    80005d38:	616d                	addi	sp,sp,240
    80005d3a:	8082                	ret
    return -1;
    80005d3c:	557d                	li	a0,-1
    80005d3e:	bfdd                	j	80005d34 <sys_unlink+0x1c6>
    iunlockput(ip);
    80005d40:	854a                	mv	a0,s2
    80005d42:	ffffe097          	auipc	ra,0xffffe
    80005d46:	230080e7          	jalr	560(ra) # 80003f72 <iunlockput>
    goto bad;
    80005d4a:	694e                	ld	s2,208(sp)
    80005d4c:	69ae                	ld	s3,200(sp)
    80005d4e:	bfc1                	j	80005d1e <sys_unlink+0x1b0>

0000000080005d50 <sys_open>:

uint64
sys_open(void)
{
    80005d50:	7131                	addi	sp,sp,-192
    80005d52:	fd06                	sd	ra,184(sp)
    80005d54:	f922                	sd	s0,176(sp)
    80005d56:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005d58:	f4c40593          	addi	a1,s0,-180
    80005d5c:	4505                	li	a0,1
    80005d5e:	ffffd097          	auipc	ra,0xffffd
    80005d62:	27c080e7          	jalr	636(ra) # 80002fda <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d66:	08000613          	li	a2,128
    80005d6a:	f5040593          	addi	a1,s0,-176
    80005d6e:	4501                	li	a0,0
    80005d70:	ffffd097          	auipc	ra,0xffffd
    80005d74:	2aa080e7          	jalr	682(ra) # 8000301a <argstr>
    80005d78:	87aa                	mv	a5,a0
    return -1;
    80005d7a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d7c:	0a07ce63          	bltz	a5,80005e38 <sys_open+0xe8>
    80005d80:	f526                	sd	s1,168(sp)

  begin_op();
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	958080e7          	jalr	-1704(ra) # 800046da <begin_op>

  if(omode & O_CREATE){
    80005d8a:	f4c42783          	lw	a5,-180(s0)
    80005d8e:	2007f793          	andi	a5,a5,512
    80005d92:	cfd5                	beqz	a5,80005e4e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d94:	4681                	li	a3,0
    80005d96:	4601                	li	a2,0
    80005d98:	4589                	li	a1,2
    80005d9a:	f5040513          	addi	a0,s0,-176
    80005d9e:	00000097          	auipc	ra,0x0
    80005da2:	95c080e7          	jalr	-1700(ra) # 800056fa <create>
    80005da6:	84aa                	mv	s1,a0
    if(ip == 0){
    80005da8:	cd41                	beqz	a0,80005e40 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005daa:	04449703          	lh	a4,68(s1)
    80005dae:	478d                	li	a5,3
    80005db0:	00f71763          	bne	a4,a5,80005dbe <sys_open+0x6e>
    80005db4:	0464d703          	lhu	a4,70(s1)
    80005db8:	47a5                	li	a5,9
    80005dba:	0ee7e163          	bltu	a5,a4,80005e9c <sys_open+0x14c>
    80005dbe:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	d28080e7          	jalr	-728(ra) # 80004ae8 <filealloc>
    80005dc8:	892a                	mv	s2,a0
    80005dca:	c97d                	beqz	a0,80005ec0 <sys_open+0x170>
    80005dcc:	ed4e                	sd	s3,152(sp)
    80005dce:	00000097          	auipc	ra,0x0
    80005dd2:	8ea080e7          	jalr	-1814(ra) # 800056b8 <fdalloc>
    80005dd6:	89aa                	mv	s3,a0
    80005dd8:	0c054e63          	bltz	a0,80005eb4 <sys_open+0x164>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005ddc:	04449703          	lh	a4,68(s1)
    80005de0:	478d                	li	a5,3
    80005de2:	0ef70c63          	beq	a4,a5,80005eda <sys_open+0x18a>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005de6:	4789                	li	a5,2
    80005de8:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005dec:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005df0:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005df4:	f4c42783          	lw	a5,-180(s0)
    80005df8:	0017c713          	xori	a4,a5,1
    80005dfc:	8b05                	andi	a4,a4,1
    80005dfe:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e02:	0037f713          	andi	a4,a5,3
    80005e06:	00e03733          	snez	a4,a4
    80005e0a:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e0e:	4007f793          	andi	a5,a5,1024
    80005e12:	c791                	beqz	a5,80005e1e <sys_open+0xce>
    80005e14:	04449703          	lh	a4,68(s1)
    80005e18:	4789                	li	a5,2
    80005e1a:	0cf70763          	beq	a4,a5,80005ee8 <sys_open+0x198>
    itrunc(ip);
  }

  iunlock(ip);
    80005e1e:	8526                	mv	a0,s1
    80005e20:	ffffe097          	auipc	ra,0xffffe
    80005e24:	fb2080e7          	jalr	-78(ra) # 80003dd2 <iunlock>
  end_op();
    80005e28:	fffff097          	auipc	ra,0xfffff
    80005e2c:	92c080e7          	jalr	-1748(ra) # 80004754 <end_op>

  return fd;
    80005e30:	854e                	mv	a0,s3
    80005e32:	74aa                	ld	s1,168(sp)
    80005e34:	790a                	ld	s2,160(sp)
    80005e36:	69ea                	ld	s3,152(sp)
}
    80005e38:	70ea                	ld	ra,184(sp)
    80005e3a:	744a                	ld	s0,176(sp)
    80005e3c:	6129                	addi	sp,sp,192
    80005e3e:	8082                	ret
      end_op();
    80005e40:	fffff097          	auipc	ra,0xfffff
    80005e44:	914080e7          	jalr	-1772(ra) # 80004754 <end_op>
      return -1;
    80005e48:	557d                	li	a0,-1
    80005e4a:	74aa                	ld	s1,168(sp)
    80005e4c:	b7f5                	j	80005e38 <sys_open+0xe8>
    if((ip = namei(path)) == 0){
    80005e4e:	f5040513          	addi	a0,s0,-176
    80005e52:	ffffe097          	auipc	ra,0xffffe
    80005e56:	688080e7          	jalr	1672(ra) # 800044da <namei>
    80005e5a:	84aa                	mv	s1,a0
    80005e5c:	c90d                	beqz	a0,80005e8e <sys_open+0x13e>
    ilock(ip);
    80005e5e:	ffffe097          	auipc	ra,0xffffe
    80005e62:	eae080e7          	jalr	-338(ra) # 80003d0c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e66:	04449703          	lh	a4,68(s1)
    80005e6a:	4785                	li	a5,1
    80005e6c:	f2f71fe3          	bne	a4,a5,80005daa <sys_open+0x5a>
    80005e70:	f4c42783          	lw	a5,-180(s0)
    80005e74:	d7a9                	beqz	a5,80005dbe <sys_open+0x6e>
      iunlockput(ip);
    80005e76:	8526                	mv	a0,s1
    80005e78:	ffffe097          	auipc	ra,0xffffe
    80005e7c:	0fa080e7          	jalr	250(ra) # 80003f72 <iunlockput>
      end_op();
    80005e80:	fffff097          	auipc	ra,0xfffff
    80005e84:	8d4080e7          	jalr	-1836(ra) # 80004754 <end_op>
      return -1;
    80005e88:	557d                	li	a0,-1
    80005e8a:	74aa                	ld	s1,168(sp)
    80005e8c:	b775                	j	80005e38 <sys_open+0xe8>
      end_op();
    80005e8e:	fffff097          	auipc	ra,0xfffff
    80005e92:	8c6080e7          	jalr	-1850(ra) # 80004754 <end_op>
      return -1;
    80005e96:	557d                	li	a0,-1
    80005e98:	74aa                	ld	s1,168(sp)
    80005e9a:	bf79                	j	80005e38 <sys_open+0xe8>
    iunlockput(ip);
    80005e9c:	8526                	mv	a0,s1
    80005e9e:	ffffe097          	auipc	ra,0xffffe
    80005ea2:	0d4080e7          	jalr	212(ra) # 80003f72 <iunlockput>
    end_op();
    80005ea6:	fffff097          	auipc	ra,0xfffff
    80005eaa:	8ae080e7          	jalr	-1874(ra) # 80004754 <end_op>
    return -1;
    80005eae:	557d                	li	a0,-1
    80005eb0:	74aa                	ld	s1,168(sp)
    80005eb2:	b759                	j	80005e38 <sys_open+0xe8>
      fileclose(f);
    80005eb4:	854a                	mv	a0,s2
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	cee080e7          	jalr	-786(ra) # 80004ba4 <fileclose>
    80005ebe:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    80005ec0:	8526                	mv	a0,s1
    80005ec2:	ffffe097          	auipc	ra,0xffffe
    80005ec6:	0b0080e7          	jalr	176(ra) # 80003f72 <iunlockput>
    end_op();
    80005eca:	fffff097          	auipc	ra,0xfffff
    80005ece:	88a080e7          	jalr	-1910(ra) # 80004754 <end_op>
    return -1;
    80005ed2:	557d                	li	a0,-1
    80005ed4:	74aa                	ld	s1,168(sp)
    80005ed6:	790a                	ld	s2,160(sp)
    80005ed8:	b785                	j	80005e38 <sys_open+0xe8>
    f->type = FD_DEVICE;
    80005eda:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005ede:	04649783          	lh	a5,70(s1)
    80005ee2:	02f91223          	sh	a5,36(s2)
    80005ee6:	b729                	j	80005df0 <sys_open+0xa0>
    itrunc(ip);
    80005ee8:	8526                	mv	a0,s1
    80005eea:	ffffe097          	auipc	ra,0xffffe
    80005eee:	f34080e7          	jalr	-204(ra) # 80003e1e <itrunc>
    80005ef2:	b735                	j	80005e1e <sys_open+0xce>

0000000080005ef4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ef4:	7175                	addi	sp,sp,-144
    80005ef6:	e506                	sd	ra,136(sp)
    80005ef8:	e122                	sd	s0,128(sp)
    80005efa:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005efc:	ffffe097          	auipc	ra,0xffffe
    80005f00:	7de080e7          	jalr	2014(ra) # 800046da <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f04:	08000613          	li	a2,128
    80005f08:	f7040593          	addi	a1,s0,-144
    80005f0c:	4501                	li	a0,0
    80005f0e:	ffffd097          	auipc	ra,0xffffd
    80005f12:	10c080e7          	jalr	268(ra) # 8000301a <argstr>
    80005f16:	02054963          	bltz	a0,80005f48 <sys_mkdir+0x54>
    80005f1a:	4681                	li	a3,0
    80005f1c:	4601                	li	a2,0
    80005f1e:	4585                	li	a1,1
    80005f20:	f7040513          	addi	a0,s0,-144
    80005f24:	fffff097          	auipc	ra,0xfffff
    80005f28:	7d6080e7          	jalr	2006(ra) # 800056fa <create>
    80005f2c:	cd11                	beqz	a0,80005f48 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f2e:	ffffe097          	auipc	ra,0xffffe
    80005f32:	044080e7          	jalr	68(ra) # 80003f72 <iunlockput>
  end_op();
    80005f36:	fffff097          	auipc	ra,0xfffff
    80005f3a:	81e080e7          	jalr	-2018(ra) # 80004754 <end_op>
  return 0;
    80005f3e:	4501                	li	a0,0
}
    80005f40:	60aa                	ld	ra,136(sp)
    80005f42:	640a                	ld	s0,128(sp)
    80005f44:	6149                	addi	sp,sp,144
    80005f46:	8082                	ret
    end_op();
    80005f48:	fffff097          	auipc	ra,0xfffff
    80005f4c:	80c080e7          	jalr	-2036(ra) # 80004754 <end_op>
    return -1;
    80005f50:	557d                	li	a0,-1
    80005f52:	b7fd                	j	80005f40 <sys_mkdir+0x4c>

0000000080005f54 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f54:	7135                	addi	sp,sp,-160
    80005f56:	ed06                	sd	ra,152(sp)
    80005f58:	e922                	sd	s0,144(sp)
    80005f5a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f5c:	ffffe097          	auipc	ra,0xffffe
    80005f60:	77e080e7          	jalr	1918(ra) # 800046da <begin_op>
  argint(1, &major);
    80005f64:	f6c40593          	addi	a1,s0,-148
    80005f68:	4505                	li	a0,1
    80005f6a:	ffffd097          	auipc	ra,0xffffd
    80005f6e:	070080e7          	jalr	112(ra) # 80002fda <argint>
  argint(2, &minor);
    80005f72:	f6840593          	addi	a1,s0,-152
    80005f76:	4509                	li	a0,2
    80005f78:	ffffd097          	auipc	ra,0xffffd
    80005f7c:	062080e7          	jalr	98(ra) # 80002fda <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f80:	08000613          	li	a2,128
    80005f84:	f7040593          	addi	a1,s0,-144
    80005f88:	4501                	li	a0,0
    80005f8a:	ffffd097          	auipc	ra,0xffffd
    80005f8e:	090080e7          	jalr	144(ra) # 8000301a <argstr>
    80005f92:	02054b63          	bltz	a0,80005fc8 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f96:	f6841683          	lh	a3,-152(s0)
    80005f9a:	f6c41603          	lh	a2,-148(s0)
    80005f9e:	458d                	li	a1,3
    80005fa0:	f7040513          	addi	a0,s0,-144
    80005fa4:	fffff097          	auipc	ra,0xfffff
    80005fa8:	756080e7          	jalr	1878(ra) # 800056fa <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fac:	cd11                	beqz	a0,80005fc8 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fae:	ffffe097          	auipc	ra,0xffffe
    80005fb2:	fc4080e7          	jalr	-60(ra) # 80003f72 <iunlockput>
  end_op();
    80005fb6:	ffffe097          	auipc	ra,0xffffe
    80005fba:	79e080e7          	jalr	1950(ra) # 80004754 <end_op>
  return 0;
    80005fbe:	4501                	li	a0,0
}
    80005fc0:	60ea                	ld	ra,152(sp)
    80005fc2:	644a                	ld	s0,144(sp)
    80005fc4:	610d                	addi	sp,sp,160
    80005fc6:	8082                	ret
    end_op();
    80005fc8:	ffffe097          	auipc	ra,0xffffe
    80005fcc:	78c080e7          	jalr	1932(ra) # 80004754 <end_op>
    return -1;
    80005fd0:	557d                	li	a0,-1
    80005fd2:	b7fd                	j	80005fc0 <sys_mknod+0x6c>

0000000080005fd4 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005fd4:	7135                	addi	sp,sp,-160
    80005fd6:	ed06                	sd	ra,152(sp)
    80005fd8:	e922                	sd	s0,144(sp)
    80005fda:	e14a                	sd	s2,128(sp)
    80005fdc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005fde:	ffffc097          	auipc	ra,0xffffc
    80005fe2:	a6c080e7          	jalr	-1428(ra) # 80001a4a <myproc>
    80005fe6:	892a                	mv	s2,a0
  
  begin_op();
    80005fe8:	ffffe097          	auipc	ra,0xffffe
    80005fec:	6f2080e7          	jalr	1778(ra) # 800046da <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ff0:	08000613          	li	a2,128
    80005ff4:	f6040593          	addi	a1,s0,-160
    80005ff8:	4501                	li	a0,0
    80005ffa:	ffffd097          	auipc	ra,0xffffd
    80005ffe:	020080e7          	jalr	32(ra) # 8000301a <argstr>
    80006002:	04054d63          	bltz	a0,8000605c <sys_chdir+0x88>
    80006006:	e526                	sd	s1,136(sp)
    80006008:	f6040513          	addi	a0,s0,-160
    8000600c:	ffffe097          	auipc	ra,0xffffe
    80006010:	4ce080e7          	jalr	1230(ra) # 800044da <namei>
    80006014:	84aa                	mv	s1,a0
    80006016:	c131                	beqz	a0,8000605a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006018:	ffffe097          	auipc	ra,0xffffe
    8000601c:	cf4080e7          	jalr	-780(ra) # 80003d0c <ilock>
  if(ip->type != T_DIR){
    80006020:	04449703          	lh	a4,68(s1)
    80006024:	4785                	li	a5,1
    80006026:	04f71163          	bne	a4,a5,80006068 <sys_chdir+0x94>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000602a:	8526                	mv	a0,s1
    8000602c:	ffffe097          	auipc	ra,0xffffe
    80006030:	da6080e7          	jalr	-602(ra) # 80003dd2 <iunlock>
  iput(p->cwd);
    80006034:	15093503          	ld	a0,336(s2)
    80006038:	ffffe097          	auipc	ra,0xffffe
    8000603c:	e92080e7          	jalr	-366(ra) # 80003eca <iput>
  end_op();
    80006040:	ffffe097          	auipc	ra,0xffffe
    80006044:	714080e7          	jalr	1812(ra) # 80004754 <end_op>
  p->cwd = ip;
    80006048:	14993823          	sd	s1,336(s2)
  return 0;
    8000604c:	4501                	li	a0,0
    8000604e:	64aa                	ld	s1,136(sp)
}
    80006050:	60ea                	ld	ra,152(sp)
    80006052:	644a                	ld	s0,144(sp)
    80006054:	690a                	ld	s2,128(sp)
    80006056:	610d                	addi	sp,sp,160
    80006058:	8082                	ret
    8000605a:	64aa                	ld	s1,136(sp)
    end_op();
    8000605c:	ffffe097          	auipc	ra,0xffffe
    80006060:	6f8080e7          	jalr	1784(ra) # 80004754 <end_op>
    return -1;
    80006064:	557d                	li	a0,-1
    80006066:	b7ed                	j	80006050 <sys_chdir+0x7c>
    iunlockput(ip);
    80006068:	8526                	mv	a0,s1
    8000606a:	ffffe097          	auipc	ra,0xffffe
    8000606e:	f08080e7          	jalr	-248(ra) # 80003f72 <iunlockput>
    end_op();
    80006072:	ffffe097          	auipc	ra,0xffffe
    80006076:	6e2080e7          	jalr	1762(ra) # 80004754 <end_op>
    return -1;
    8000607a:	557d                	li	a0,-1
    8000607c:	64aa                	ld	s1,136(sp)
    8000607e:	bfc9                	j	80006050 <sys_chdir+0x7c>

0000000080006080 <sys_exec>:

uint64
sys_exec(void)
{
    80006080:	7121                	addi	sp,sp,-448
    80006082:	ff06                	sd	ra,440(sp)
    80006084:	fb22                	sd	s0,432(sp)
    80006086:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006088:	e4840593          	addi	a1,s0,-440
    8000608c:	4505                	li	a0,1
    8000608e:	ffffd097          	auipc	ra,0xffffd
    80006092:	f6c080e7          	jalr	-148(ra) # 80002ffa <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006096:	08000613          	li	a2,128
    8000609a:	f5040593          	addi	a1,s0,-176
    8000609e:	4501                	li	a0,0
    800060a0:	ffffd097          	auipc	ra,0xffffd
    800060a4:	f7a080e7          	jalr	-134(ra) # 8000301a <argstr>
    800060a8:	87aa                	mv	a5,a0
    return -1;
    800060aa:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800060ac:	0e07c263          	bltz	a5,80006190 <sys_exec+0x110>
    800060b0:	f726                	sd	s1,424(sp)
    800060b2:	f34a                	sd	s2,416(sp)
    800060b4:	ef4e                	sd	s3,408(sp)
    800060b6:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    800060b8:	10000613          	li	a2,256
    800060bc:	4581                	li	a1,0
    800060be:	e5040513          	addi	a0,s0,-432
    800060c2:	ffffb097          	auipc	ra,0xffffb
    800060c6:	c72080e7          	jalr	-910(ra) # 80000d34 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060ca:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    800060ce:	89a6                	mv	s3,s1
    800060d0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800060d2:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060d6:	00391513          	slli	a0,s2,0x3
    800060da:	e4040593          	addi	a1,s0,-448
    800060de:	e4843783          	ld	a5,-440(s0)
    800060e2:	953e                	add	a0,a0,a5
    800060e4:	ffffd097          	auipc	ra,0xffffd
    800060e8:	e58080e7          	jalr	-424(ra) # 80002f3c <fetchaddr>
    800060ec:	02054a63          	bltz	a0,80006120 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    800060f0:	e4043783          	ld	a5,-448(s0)
    800060f4:	c7b9                	beqz	a5,80006142 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060f6:	ffffb097          	auipc	ra,0xffffb
    800060fa:	a52080e7          	jalr	-1454(ra) # 80000b48 <kalloc>
    800060fe:	85aa                	mv	a1,a0
    80006100:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006104:	cd11                	beqz	a0,80006120 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006106:	6605                	lui	a2,0x1
    80006108:	e4043503          	ld	a0,-448(s0)
    8000610c:	ffffd097          	auipc	ra,0xffffd
    80006110:	e82080e7          	jalr	-382(ra) # 80002f8e <fetchstr>
    80006114:	00054663          	bltz	a0,80006120 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80006118:	0905                	addi	s2,s2,1
    8000611a:	09a1                	addi	s3,s3,8
    8000611c:	fb491de3          	bne	s2,s4,800060d6 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006120:	f5040913          	addi	s2,s0,-176
    80006124:	6088                	ld	a0,0(s1)
    80006126:	c125                	beqz	a0,80006186 <sys_exec+0x106>
    kfree(argv[i]);
    80006128:	ffffb097          	auipc	ra,0xffffb
    8000612c:	922080e7          	jalr	-1758(ra) # 80000a4a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006130:	04a1                	addi	s1,s1,8
    80006132:	ff2499e3          	bne	s1,s2,80006124 <sys_exec+0xa4>
  return -1;
    80006136:	557d                	li	a0,-1
    80006138:	74ba                	ld	s1,424(sp)
    8000613a:	791a                	ld	s2,416(sp)
    8000613c:	69fa                	ld	s3,408(sp)
    8000613e:	6a5a                	ld	s4,400(sp)
    80006140:	a881                	j	80006190 <sys_exec+0x110>
      argv[i] = 0;
    80006142:	0009079b          	sext.w	a5,s2
    80006146:	078e                	slli	a5,a5,0x3
    80006148:	fd078793          	addi	a5,a5,-48
    8000614c:	97a2                	add	a5,a5,s0
    8000614e:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80006152:	e5040593          	addi	a1,s0,-432
    80006156:	f5040513          	addi	a0,s0,-176
    8000615a:	fffff097          	auipc	ra,0xfffff
    8000615e:	120080e7          	jalr	288(ra) # 8000527a <exec>
    80006162:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006164:	f5040993          	addi	s3,s0,-176
    80006168:	6088                	ld	a0,0(s1)
    8000616a:	c901                	beqz	a0,8000617a <sys_exec+0xfa>
    kfree(argv[i]);
    8000616c:	ffffb097          	auipc	ra,0xffffb
    80006170:	8de080e7          	jalr	-1826(ra) # 80000a4a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006174:	04a1                	addi	s1,s1,8
    80006176:	ff3499e3          	bne	s1,s3,80006168 <sys_exec+0xe8>
  return ret;
    8000617a:	854a                	mv	a0,s2
    8000617c:	74ba                	ld	s1,424(sp)
    8000617e:	791a                	ld	s2,416(sp)
    80006180:	69fa                	ld	s3,408(sp)
    80006182:	6a5a                	ld	s4,400(sp)
    80006184:	a031                	j	80006190 <sys_exec+0x110>
  return -1;
    80006186:	557d                	li	a0,-1
    80006188:	74ba                	ld	s1,424(sp)
    8000618a:	791a                	ld	s2,416(sp)
    8000618c:	69fa                	ld	s3,408(sp)
    8000618e:	6a5a                	ld	s4,400(sp)
}
    80006190:	70fa                	ld	ra,440(sp)
    80006192:	745a                	ld	s0,432(sp)
    80006194:	6139                	addi	sp,sp,448
    80006196:	8082                	ret

0000000080006198 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006198:	7139                	addi	sp,sp,-64
    8000619a:	fc06                	sd	ra,56(sp)
    8000619c:	f822                	sd	s0,48(sp)
    8000619e:	f426                	sd	s1,40(sp)
    800061a0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800061a2:	ffffc097          	auipc	ra,0xffffc
    800061a6:	8a8080e7          	jalr	-1880(ra) # 80001a4a <myproc>
    800061aa:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800061ac:	fd840593          	addi	a1,s0,-40
    800061b0:	4501                	li	a0,0
    800061b2:	ffffd097          	auipc	ra,0xffffd
    800061b6:	e48080e7          	jalr	-440(ra) # 80002ffa <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800061ba:	fc840593          	addi	a1,s0,-56
    800061be:	fd040513          	addi	a0,s0,-48
    800061c2:	fffff097          	auipc	ra,0xfffff
    800061c6:	d50080e7          	jalr	-688(ra) # 80004f12 <pipealloc>
    return -1;
    800061ca:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061cc:	0c054463          	bltz	a0,80006294 <sys_pipe+0xfc>
  fd0 = -1;
    800061d0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061d4:	fd043503          	ld	a0,-48(s0)
    800061d8:	fffff097          	auipc	ra,0xfffff
    800061dc:	4e0080e7          	jalr	1248(ra) # 800056b8 <fdalloc>
    800061e0:	fca42223          	sw	a0,-60(s0)
    800061e4:	08054b63          	bltz	a0,8000627a <sys_pipe+0xe2>
    800061e8:	fc843503          	ld	a0,-56(s0)
    800061ec:	fffff097          	auipc	ra,0xfffff
    800061f0:	4cc080e7          	jalr	1228(ra) # 800056b8 <fdalloc>
    800061f4:	fca42023          	sw	a0,-64(s0)
    800061f8:	06054863          	bltz	a0,80006268 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061fc:	4691                	li	a3,4
    800061fe:	fc440613          	addi	a2,s0,-60
    80006202:	fd843583          	ld	a1,-40(s0)
    80006206:	68a8                	ld	a0,80(s1)
    80006208:	ffffb097          	auipc	ra,0xffffb
    8000620c:	4da080e7          	jalr	1242(ra) # 800016e2 <copyout>
    80006210:	02054063          	bltz	a0,80006230 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006214:	4691                	li	a3,4
    80006216:	fc040613          	addi	a2,s0,-64
    8000621a:	fd843583          	ld	a1,-40(s0)
    8000621e:	0591                	addi	a1,a1,4
    80006220:	68a8                	ld	a0,80(s1)
    80006222:	ffffb097          	auipc	ra,0xffffb
    80006226:	4c0080e7          	jalr	1216(ra) # 800016e2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000622a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000622c:	06055463          	bgez	a0,80006294 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006230:	fc442783          	lw	a5,-60(s0)
    80006234:	07e9                	addi	a5,a5,26
    80006236:	078e                	slli	a5,a5,0x3
    80006238:	97a6                	add	a5,a5,s1
    8000623a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000623e:	fc042783          	lw	a5,-64(s0)
    80006242:	07e9                	addi	a5,a5,26
    80006244:	078e                	slli	a5,a5,0x3
    80006246:	94be                	add	s1,s1,a5
    80006248:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000624c:	fd043503          	ld	a0,-48(s0)
    80006250:	fffff097          	auipc	ra,0xfffff
    80006254:	954080e7          	jalr	-1708(ra) # 80004ba4 <fileclose>
    fileclose(wf);
    80006258:	fc843503          	ld	a0,-56(s0)
    8000625c:	fffff097          	auipc	ra,0xfffff
    80006260:	948080e7          	jalr	-1720(ra) # 80004ba4 <fileclose>
    return -1;
    80006264:	57fd                	li	a5,-1
    80006266:	a03d                	j	80006294 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006268:	fc442783          	lw	a5,-60(s0)
    8000626c:	0007c763          	bltz	a5,8000627a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006270:	07e9                	addi	a5,a5,26
    80006272:	078e                	slli	a5,a5,0x3
    80006274:	97a6                	add	a5,a5,s1
    80006276:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    8000627a:	fd043503          	ld	a0,-48(s0)
    8000627e:	fffff097          	auipc	ra,0xfffff
    80006282:	926080e7          	jalr	-1754(ra) # 80004ba4 <fileclose>
    fileclose(wf);
    80006286:	fc843503          	ld	a0,-56(s0)
    8000628a:	fffff097          	auipc	ra,0xfffff
    8000628e:	91a080e7          	jalr	-1766(ra) # 80004ba4 <fileclose>
    return -1;
    80006292:	57fd                	li	a5,-1
}
    80006294:	853e                	mv	a0,a5
    80006296:	70e2                	ld	ra,56(sp)
    80006298:	7442                	ld	s0,48(sp)
    8000629a:	74a2                	ld	s1,40(sp)
    8000629c:	6121                	addi	sp,sp,64
    8000629e:	8082                	ret

00000000800062a0 <kernelvec>:
    800062a0:	7111                	addi	sp,sp,-256
    800062a2:	e006                	sd	ra,0(sp)
    800062a4:	e40a                	sd	sp,8(sp)
    800062a6:	e80e                	sd	gp,16(sp)
    800062a8:	ec12                	sd	tp,24(sp)
    800062aa:	f016                	sd	t0,32(sp)
    800062ac:	f41a                	sd	t1,40(sp)
    800062ae:	f81e                	sd	t2,48(sp)
    800062b0:	fc22                	sd	s0,56(sp)
    800062b2:	e0a6                	sd	s1,64(sp)
    800062b4:	e4aa                	sd	a0,72(sp)
    800062b6:	e8ae                	sd	a1,80(sp)
    800062b8:	ecb2                	sd	a2,88(sp)
    800062ba:	f0b6                	sd	a3,96(sp)
    800062bc:	f4ba                	sd	a4,104(sp)
    800062be:	f8be                	sd	a5,112(sp)
    800062c0:	fcc2                	sd	a6,120(sp)
    800062c2:	e146                	sd	a7,128(sp)
    800062c4:	e54a                	sd	s2,136(sp)
    800062c6:	e94e                	sd	s3,144(sp)
    800062c8:	ed52                	sd	s4,152(sp)
    800062ca:	f156                	sd	s5,160(sp)
    800062cc:	f55a                	sd	s6,168(sp)
    800062ce:	f95e                	sd	s7,176(sp)
    800062d0:	fd62                	sd	s8,184(sp)
    800062d2:	e1e6                	sd	s9,192(sp)
    800062d4:	e5ea                	sd	s10,200(sp)
    800062d6:	e9ee                	sd	s11,208(sp)
    800062d8:	edf2                	sd	t3,216(sp)
    800062da:	f1f6                	sd	t4,224(sp)
    800062dc:	f5fa                	sd	t5,232(sp)
    800062de:	f9fe                	sd	t6,240(sp)
    800062e0:	b29fc0ef          	jal	80002e08 <kerneltrap>
    800062e4:	6082                	ld	ra,0(sp)
    800062e6:	6122                	ld	sp,8(sp)
    800062e8:	61c2                	ld	gp,16(sp)
    800062ea:	7282                	ld	t0,32(sp)
    800062ec:	7322                	ld	t1,40(sp)
    800062ee:	73c2                	ld	t2,48(sp)
    800062f0:	7462                	ld	s0,56(sp)
    800062f2:	6486                	ld	s1,64(sp)
    800062f4:	6526                	ld	a0,72(sp)
    800062f6:	65c6                	ld	a1,80(sp)
    800062f8:	6666                	ld	a2,88(sp)
    800062fa:	7686                	ld	a3,96(sp)
    800062fc:	7726                	ld	a4,104(sp)
    800062fe:	77c6                	ld	a5,112(sp)
    80006300:	7866                	ld	a6,120(sp)
    80006302:	688a                	ld	a7,128(sp)
    80006304:	692a                	ld	s2,136(sp)
    80006306:	69ca                	ld	s3,144(sp)
    80006308:	6a6a                	ld	s4,152(sp)
    8000630a:	7a8a                	ld	s5,160(sp)
    8000630c:	7b2a                	ld	s6,168(sp)
    8000630e:	7bca                	ld	s7,176(sp)
    80006310:	7c6a                	ld	s8,184(sp)
    80006312:	6c8e                	ld	s9,192(sp)
    80006314:	6d2e                	ld	s10,200(sp)
    80006316:	6dce                	ld	s11,208(sp)
    80006318:	6e6e                	ld	t3,216(sp)
    8000631a:	7e8e                	ld	t4,224(sp)
    8000631c:	7f2e                	ld	t5,232(sp)
    8000631e:	7fce                	ld	t6,240(sp)
    80006320:	6111                	addi	sp,sp,256
    80006322:	10200073          	sret
    80006326:	00000013          	nop
    8000632a:	00000013          	nop
    8000632e:	0001                	nop

0000000080006330 <timervec>:
    80006330:	34051573          	csrrw	a0,mscratch,a0
    80006334:	e10c                	sd	a1,0(a0)
    80006336:	e510                	sd	a2,8(a0)
    80006338:	e914                	sd	a3,16(a0)
    8000633a:	6d0c                	ld	a1,24(a0)
    8000633c:	7110                	ld	a2,32(a0)
    8000633e:	6194                	ld	a3,0(a1)
    80006340:	96b2                	add	a3,a3,a2
    80006342:	e194                	sd	a3,0(a1)
    80006344:	4589                	li	a1,2
    80006346:	14459073          	csrw	sip,a1
    8000634a:	6914                	ld	a3,16(a0)
    8000634c:	6510                	ld	a2,8(a0)
    8000634e:	610c                	ld	a1,0(a0)
    80006350:	34051573          	csrrw	a0,mscratch,a0
    80006354:	30200073          	mret
	...

000000008000635a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000635a:	1141                	addi	sp,sp,-16
    8000635c:	e422                	sd	s0,8(sp)
    8000635e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006360:	0c0007b7          	lui	a5,0xc000
    80006364:	4705                	li	a4,1
    80006366:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006368:	0c0007b7          	lui	a5,0xc000
    8000636c:	c3d8                	sw	a4,4(a5)
}
    8000636e:	6422                	ld	s0,8(sp)
    80006370:	0141                	addi	sp,sp,16
    80006372:	8082                	ret

0000000080006374 <plicinithart>:

void
plicinithart(void)
{
    80006374:	1141                	addi	sp,sp,-16
    80006376:	e406                	sd	ra,8(sp)
    80006378:	e022                	sd	s0,0(sp)
    8000637a:	0800                	addi	s0,sp,16
  int hart = cpuid();
    8000637c:	ffffb097          	auipc	ra,0xffffb
    80006380:	6a2080e7          	jalr	1698(ra) # 80001a1e <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006384:	0085171b          	slliw	a4,a0,0x8
    80006388:	0c0027b7          	lui	a5,0xc002
    8000638c:	97ba                	add	a5,a5,a4
    8000638e:	40200713          	li	a4,1026
    80006392:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006396:	00d5151b          	slliw	a0,a0,0xd
    8000639a:	0c2017b7          	lui	a5,0xc201
    8000639e:	97aa                	add	a5,a5,a0
    800063a0:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800063a4:	60a2                	ld	ra,8(sp)
    800063a6:	6402                	ld	s0,0(sp)
    800063a8:	0141                	addi	sp,sp,16
    800063aa:	8082                	ret

00000000800063ac <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063ac:	1141                	addi	sp,sp,-16
    800063ae:	e406                	sd	ra,8(sp)
    800063b0:	e022                	sd	s0,0(sp)
    800063b2:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063b4:	ffffb097          	auipc	ra,0xffffb
    800063b8:	66a080e7          	jalr	1642(ra) # 80001a1e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063bc:	00d5151b          	slliw	a0,a0,0xd
    800063c0:	0c2017b7          	lui	a5,0xc201
    800063c4:	97aa                	add	a5,a5,a0
  return irq;
}
    800063c6:	43c8                	lw	a0,4(a5)
    800063c8:	60a2                	ld	ra,8(sp)
    800063ca:	6402                	ld	s0,0(sp)
    800063cc:	0141                	addi	sp,sp,16
    800063ce:	8082                	ret

00000000800063d0 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063d0:	1101                	addi	sp,sp,-32
    800063d2:	ec06                	sd	ra,24(sp)
    800063d4:	e822                	sd	s0,16(sp)
    800063d6:	e426                	sd	s1,8(sp)
    800063d8:	1000                	addi	s0,sp,32
    800063da:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063dc:	ffffb097          	auipc	ra,0xffffb
    800063e0:	642080e7          	jalr	1602(ra) # 80001a1e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063e4:	00d5151b          	slliw	a0,a0,0xd
    800063e8:	0c2017b7          	lui	a5,0xc201
    800063ec:	97aa                	add	a5,a5,a0
    800063ee:	c3c4                	sw	s1,4(a5)
}
    800063f0:	60e2                	ld	ra,24(sp)
    800063f2:	6442                	ld	s0,16(sp)
    800063f4:	64a2                	ld	s1,8(sp)
    800063f6:	6105                	addi	sp,sp,32
    800063f8:	8082                	ret

00000000800063fa <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063fa:	1141                	addi	sp,sp,-16
    800063fc:	e406                	sd	ra,8(sp)
    800063fe:	e022                	sd	s0,0(sp)
    80006400:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006402:	479d                	li	a5,7
    80006404:	04a7cc63          	blt	a5,a0,8000645c <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006408:	00021797          	auipc	a5,0x21
    8000640c:	0e878793          	addi	a5,a5,232 # 800274f0 <disk>
    80006410:	97aa                	add	a5,a5,a0
    80006412:	0187c783          	lbu	a5,24(a5)
    80006416:	ebb9                	bnez	a5,8000646c <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006418:	00451693          	slli	a3,a0,0x4
    8000641c:	00021797          	auipc	a5,0x21
    80006420:	0d478793          	addi	a5,a5,212 # 800274f0 <disk>
    80006424:	6398                	ld	a4,0(a5)
    80006426:	9736                	add	a4,a4,a3
    80006428:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    8000642c:	6398                	ld	a4,0(a5)
    8000642e:	9736                	add	a4,a4,a3
    80006430:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006434:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006438:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    8000643c:	97aa                	add	a5,a5,a0
    8000643e:	4705                	li	a4,1
    80006440:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006444:	00021517          	auipc	a0,0x21
    80006448:	0c450513          	addi	a0,a0,196 # 80027508 <disk+0x18>
    8000644c:	ffffc097          	auipc	ra,0xffffc
    80006450:	ec6080e7          	jalr	-314(ra) # 80002312 <wakeup>
}
    80006454:	60a2                	ld	ra,8(sp)
    80006456:	6402                	ld	s0,0(sp)
    80006458:	0141                	addi	sp,sp,16
    8000645a:	8082                	ret
    panic("free_desc 1");
    8000645c:	00002517          	auipc	a0,0x2
    80006460:	1e450513          	addi	a0,a0,484 # 80008640 <etext+0x640>
    80006464:	ffffa097          	auipc	ra,0xffffa
    80006468:	0fc080e7          	jalr	252(ra) # 80000560 <panic>
    panic("free_desc 2");
    8000646c:	00002517          	auipc	a0,0x2
    80006470:	1e450513          	addi	a0,a0,484 # 80008650 <etext+0x650>
    80006474:	ffffa097          	auipc	ra,0xffffa
    80006478:	0ec080e7          	jalr	236(ra) # 80000560 <panic>

000000008000647c <virtio_disk_init>:
{
    8000647c:	1101                	addi	sp,sp,-32
    8000647e:	ec06                	sd	ra,24(sp)
    80006480:	e822                	sd	s0,16(sp)
    80006482:	e426                	sd	s1,8(sp)
    80006484:	e04a                	sd	s2,0(sp)
    80006486:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006488:	00002597          	auipc	a1,0x2
    8000648c:	1d858593          	addi	a1,a1,472 # 80008660 <etext+0x660>
    80006490:	00021517          	auipc	a0,0x21
    80006494:	18850513          	addi	a0,a0,392 # 80027618 <disk+0x128>
    80006498:	ffffa097          	auipc	ra,0xffffa
    8000649c:	710080e7          	jalr	1808(ra) # 80000ba8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064a0:	100017b7          	lui	a5,0x10001
    800064a4:	4398                	lw	a4,0(a5)
    800064a6:	2701                	sext.w	a4,a4
    800064a8:	747277b7          	lui	a5,0x74727
    800064ac:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064b0:	18f71c63          	bne	a4,a5,80006648 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800064b4:	100017b7          	lui	a5,0x10001
    800064b8:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    800064ba:	439c                	lw	a5,0(a5)
    800064bc:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064be:	4709                	li	a4,2
    800064c0:	18e79463          	bne	a5,a4,80006648 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064c4:	100017b7          	lui	a5,0x10001
    800064c8:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    800064ca:	439c                	lw	a5,0(a5)
    800064cc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800064ce:	16e79d63          	bne	a5,a4,80006648 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064d2:	100017b7          	lui	a5,0x10001
    800064d6:	47d8                	lw	a4,12(a5)
    800064d8:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064da:	554d47b7          	lui	a5,0x554d4
    800064de:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064e2:	16f71363          	bne	a4,a5,80006648 <virtio_disk_init+0x1cc>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064e6:	100017b7          	lui	a5,0x10001
    800064ea:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064ee:	4705                	li	a4,1
    800064f0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064f2:	470d                	li	a4,3
    800064f4:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800064f6:	10001737          	lui	a4,0x10001
    800064fa:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800064fc:	c7ffe737          	lui	a4,0xc7ffe
    80006500:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd712f>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006504:	8ef9                	and	a3,a3,a4
    80006506:	10001737          	lui	a4,0x10001
    8000650a:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000650c:	472d                	li	a4,11
    8000650e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006510:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    80006514:	439c                	lw	a5,0(a5)
    80006516:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    8000651a:	8ba1                	andi	a5,a5,8
    8000651c:	12078e63          	beqz	a5,80006658 <virtio_disk_init+0x1dc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006520:	100017b7          	lui	a5,0x10001
    80006524:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006528:	100017b7          	lui	a5,0x10001
    8000652c:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    80006530:	439c                	lw	a5,0(a5)
    80006532:	2781                	sext.w	a5,a5
    80006534:	12079a63          	bnez	a5,80006668 <virtio_disk_init+0x1ec>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006538:	100017b7          	lui	a5,0x10001
    8000653c:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    80006540:	439c                	lw	a5,0(a5)
    80006542:	2781                	sext.w	a5,a5
  if(max == 0)
    80006544:	12078a63          	beqz	a5,80006678 <virtio_disk_init+0x1fc>
  if(max < NUM)
    80006548:	471d                	li	a4,7
    8000654a:	12f77f63          	bgeu	a4,a5,80006688 <virtio_disk_init+0x20c>
  disk.desc = kalloc();
    8000654e:	ffffa097          	auipc	ra,0xffffa
    80006552:	5fa080e7          	jalr	1530(ra) # 80000b48 <kalloc>
    80006556:	00021497          	auipc	s1,0x21
    8000655a:	f9a48493          	addi	s1,s1,-102 # 800274f0 <disk>
    8000655e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006560:	ffffa097          	auipc	ra,0xffffa
    80006564:	5e8080e7          	jalr	1512(ra) # 80000b48 <kalloc>
    80006568:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000656a:	ffffa097          	auipc	ra,0xffffa
    8000656e:	5de080e7          	jalr	1502(ra) # 80000b48 <kalloc>
    80006572:	87aa                	mv	a5,a0
    80006574:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006576:	6088                	ld	a0,0(s1)
    80006578:	12050063          	beqz	a0,80006698 <virtio_disk_init+0x21c>
    8000657c:	00021717          	auipc	a4,0x21
    80006580:	f7c73703          	ld	a4,-132(a4) # 800274f8 <disk+0x8>
    80006584:	10070a63          	beqz	a4,80006698 <virtio_disk_init+0x21c>
    80006588:	10078863          	beqz	a5,80006698 <virtio_disk_init+0x21c>
  memset(disk.desc, 0, PGSIZE);
    8000658c:	6605                	lui	a2,0x1
    8000658e:	4581                	li	a1,0
    80006590:	ffffa097          	auipc	ra,0xffffa
    80006594:	7a4080e7          	jalr	1956(ra) # 80000d34 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006598:	00021497          	auipc	s1,0x21
    8000659c:	f5848493          	addi	s1,s1,-168 # 800274f0 <disk>
    800065a0:	6605                	lui	a2,0x1
    800065a2:	4581                	li	a1,0
    800065a4:	6488                	ld	a0,8(s1)
    800065a6:	ffffa097          	auipc	ra,0xffffa
    800065aa:	78e080e7          	jalr	1934(ra) # 80000d34 <memset>
  memset(disk.used, 0, PGSIZE);
    800065ae:	6605                	lui	a2,0x1
    800065b0:	4581                	li	a1,0
    800065b2:	6888                	ld	a0,16(s1)
    800065b4:	ffffa097          	auipc	ra,0xffffa
    800065b8:	780080e7          	jalr	1920(ra) # 80000d34 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800065bc:	100017b7          	lui	a5,0x10001
    800065c0:	4721                	li	a4,8
    800065c2:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800065c4:	4098                	lw	a4,0(s1)
    800065c6:	100017b7          	lui	a5,0x10001
    800065ca:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800065ce:	40d8                	lw	a4,4(s1)
    800065d0:	100017b7          	lui	a5,0x10001
    800065d4:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800065d8:	649c                	ld	a5,8(s1)
    800065da:	0007869b          	sext.w	a3,a5
    800065de:	10001737          	lui	a4,0x10001
    800065e2:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800065e6:	9781                	srai	a5,a5,0x20
    800065e8:	10001737          	lui	a4,0x10001
    800065ec:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800065f0:	689c                	ld	a5,16(s1)
    800065f2:	0007869b          	sext.w	a3,a5
    800065f6:	10001737          	lui	a4,0x10001
    800065fa:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800065fe:	9781                	srai	a5,a5,0x20
    80006600:	10001737          	lui	a4,0x10001
    80006604:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006608:	10001737          	lui	a4,0x10001
    8000660c:	4785                	li	a5,1
    8000660e:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    80006610:	00f48c23          	sb	a5,24(s1)
    80006614:	00f48ca3          	sb	a5,25(s1)
    80006618:	00f48d23          	sb	a5,26(s1)
    8000661c:	00f48da3          	sb	a5,27(s1)
    80006620:	00f48e23          	sb	a5,28(s1)
    80006624:	00f48ea3          	sb	a5,29(s1)
    80006628:	00f48f23          	sb	a5,30(s1)
    8000662c:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006630:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006634:	100017b7          	lui	a5,0x10001
    80006638:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    8000663c:	60e2                	ld	ra,24(sp)
    8000663e:	6442                	ld	s0,16(sp)
    80006640:	64a2                	ld	s1,8(sp)
    80006642:	6902                	ld	s2,0(sp)
    80006644:	6105                	addi	sp,sp,32
    80006646:	8082                	ret
    panic("could not find virtio disk");
    80006648:	00002517          	auipc	a0,0x2
    8000664c:	02850513          	addi	a0,a0,40 # 80008670 <etext+0x670>
    80006650:	ffffa097          	auipc	ra,0xffffa
    80006654:	f10080e7          	jalr	-240(ra) # 80000560 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006658:	00002517          	auipc	a0,0x2
    8000665c:	03850513          	addi	a0,a0,56 # 80008690 <etext+0x690>
    80006660:	ffffa097          	auipc	ra,0xffffa
    80006664:	f00080e7          	jalr	-256(ra) # 80000560 <panic>
    panic("virtio disk should not be ready");
    80006668:	00002517          	auipc	a0,0x2
    8000666c:	04850513          	addi	a0,a0,72 # 800086b0 <etext+0x6b0>
    80006670:	ffffa097          	auipc	ra,0xffffa
    80006674:	ef0080e7          	jalr	-272(ra) # 80000560 <panic>
    panic("virtio disk has no queue 0");
    80006678:	00002517          	auipc	a0,0x2
    8000667c:	05850513          	addi	a0,a0,88 # 800086d0 <etext+0x6d0>
    80006680:	ffffa097          	auipc	ra,0xffffa
    80006684:	ee0080e7          	jalr	-288(ra) # 80000560 <panic>
    panic("virtio disk max queue too short");
    80006688:	00002517          	auipc	a0,0x2
    8000668c:	06850513          	addi	a0,a0,104 # 800086f0 <etext+0x6f0>
    80006690:	ffffa097          	auipc	ra,0xffffa
    80006694:	ed0080e7          	jalr	-304(ra) # 80000560 <panic>
    panic("virtio disk kalloc");
    80006698:	00002517          	auipc	a0,0x2
    8000669c:	07850513          	addi	a0,a0,120 # 80008710 <etext+0x710>
    800066a0:	ffffa097          	auipc	ra,0xffffa
    800066a4:	ec0080e7          	jalr	-320(ra) # 80000560 <panic>

00000000800066a8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800066a8:	7159                	addi	sp,sp,-112
    800066aa:	f486                	sd	ra,104(sp)
    800066ac:	f0a2                	sd	s0,96(sp)
    800066ae:	eca6                	sd	s1,88(sp)
    800066b0:	e8ca                	sd	s2,80(sp)
    800066b2:	e4ce                	sd	s3,72(sp)
    800066b4:	e0d2                	sd	s4,64(sp)
    800066b6:	fc56                	sd	s5,56(sp)
    800066b8:	f85a                	sd	s6,48(sp)
    800066ba:	f45e                	sd	s7,40(sp)
    800066bc:	f062                	sd	s8,32(sp)
    800066be:	ec66                	sd	s9,24(sp)
    800066c0:	1880                	addi	s0,sp,112
    800066c2:	8a2a                	mv	s4,a0
    800066c4:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800066c6:	00c52c83          	lw	s9,12(a0)
    800066ca:	001c9c9b          	slliw	s9,s9,0x1
    800066ce:	1c82                	slli	s9,s9,0x20
    800066d0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800066d4:	00021517          	auipc	a0,0x21
    800066d8:	f4450513          	addi	a0,a0,-188 # 80027618 <disk+0x128>
    800066dc:	ffffa097          	auipc	ra,0xffffa
    800066e0:	55c080e7          	jalr	1372(ra) # 80000c38 <acquire>
  for(int i = 0; i < 3; i++){
    800066e4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800066e6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800066e8:	00021b17          	auipc	s6,0x21
    800066ec:	e08b0b13          	addi	s6,s6,-504 # 800274f0 <disk>
  for(int i = 0; i < 3; i++){
    800066f0:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066f2:	00021c17          	auipc	s8,0x21
    800066f6:	f26c0c13          	addi	s8,s8,-218 # 80027618 <disk+0x128>
    800066fa:	a0ad                	j	80006764 <virtio_disk_rw+0xbc>
      disk.free[i] = 0;
    800066fc:	00fb0733          	add	a4,s6,a5
    80006700:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    80006704:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006706:	0207c563          	bltz	a5,80006730 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000670a:	2905                	addiw	s2,s2,1
    8000670c:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000670e:	05590f63          	beq	s2,s5,8000676c <virtio_disk_rw+0xc4>
    idx[i] = alloc_desc();
    80006712:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006714:	00021717          	auipc	a4,0x21
    80006718:	ddc70713          	addi	a4,a4,-548 # 800274f0 <disk>
    8000671c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000671e:	01874683          	lbu	a3,24(a4)
    80006722:	fee9                	bnez	a3,800066fc <virtio_disk_rw+0x54>
  for(int i = 0; i < NUM; i++){
    80006724:	2785                	addiw	a5,a5,1
    80006726:	0705                	addi	a4,a4,1
    80006728:	fe979be3          	bne	a5,s1,8000671e <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000672c:	57fd                	li	a5,-1
    8000672e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006730:	03205163          	blez	s2,80006752 <virtio_disk_rw+0xaa>
        free_desc(idx[j]);
    80006734:	f9042503          	lw	a0,-112(s0)
    80006738:	00000097          	auipc	ra,0x0
    8000673c:	cc2080e7          	jalr	-830(ra) # 800063fa <free_desc>
      for(int j = 0; j < i; j++)
    80006740:	4785                	li	a5,1
    80006742:	0127d863          	bge	a5,s2,80006752 <virtio_disk_rw+0xaa>
        free_desc(idx[j]);
    80006746:	f9442503          	lw	a0,-108(s0)
    8000674a:	00000097          	auipc	ra,0x0
    8000674e:	cb0080e7          	jalr	-848(ra) # 800063fa <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006752:	85e2                	mv	a1,s8
    80006754:	00021517          	auipc	a0,0x21
    80006758:	db450513          	addi	a0,a0,-588 # 80027508 <disk+0x18>
    8000675c:	ffffc097          	auipc	ra,0xffffc
    80006760:	b52080e7          	jalr	-1198(ra) # 800022ae <sleep>
  for(int i = 0; i < 3; i++){
    80006764:	f9040613          	addi	a2,s0,-112
    80006768:	894e                	mv	s2,s3
    8000676a:	b765                	j	80006712 <virtio_disk_rw+0x6a>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000676c:	f9042503          	lw	a0,-112(s0)
    80006770:	00451693          	slli	a3,a0,0x4

  if(write)
    80006774:	00021797          	auipc	a5,0x21
    80006778:	d7c78793          	addi	a5,a5,-644 # 800274f0 <disk>
    8000677c:	00a50713          	addi	a4,a0,10
    80006780:	0712                	slli	a4,a4,0x4
    80006782:	973e                	add	a4,a4,a5
    80006784:	01703633          	snez	a2,s7
    80006788:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000678a:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    8000678e:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006792:	6398                	ld	a4,0(a5)
    80006794:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006796:	0a868613          	addi	a2,a3,168
    8000679a:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000679c:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000679e:	6390                	ld	a2,0(a5)
    800067a0:	00d605b3          	add	a1,a2,a3
    800067a4:	4741                	li	a4,16
    800067a6:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800067a8:	4805                	li	a6,1
    800067aa:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    800067ae:	f9442703          	lw	a4,-108(s0)
    800067b2:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800067b6:	0712                	slli	a4,a4,0x4
    800067b8:	963a                	add	a2,a2,a4
    800067ba:	058a0593          	addi	a1,s4,88
    800067be:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800067c0:	0007b883          	ld	a7,0(a5)
    800067c4:	9746                	add	a4,a4,a7
    800067c6:	40000613          	li	a2,1024
    800067ca:	c710                	sw	a2,8(a4)
  if(write)
    800067cc:	001bb613          	seqz	a2,s7
    800067d0:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800067d4:	00166613          	ori	a2,a2,1
    800067d8:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800067dc:	f9842583          	lw	a1,-104(s0)
    800067e0:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800067e4:	00250613          	addi	a2,a0,2
    800067e8:	0612                	slli	a2,a2,0x4
    800067ea:	963e                	add	a2,a2,a5
    800067ec:	577d                	li	a4,-1
    800067ee:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800067f2:	0592                	slli	a1,a1,0x4
    800067f4:	98ae                	add	a7,a7,a1
    800067f6:	03068713          	addi	a4,a3,48
    800067fa:	973e                	add	a4,a4,a5
    800067fc:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    80006800:	6398                	ld	a4,0(a5)
    80006802:	972e                	add	a4,a4,a1
    80006804:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006808:	4689                	li	a3,2
    8000680a:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    8000680e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006812:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    80006816:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000681a:	6794                	ld	a3,8(a5)
    8000681c:	0026d703          	lhu	a4,2(a3)
    80006820:	8b1d                	andi	a4,a4,7
    80006822:	0706                	slli	a4,a4,0x1
    80006824:	96ba                	add	a3,a3,a4
    80006826:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    8000682a:	0330000f          	fence	rw,rw

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000682e:	6798                	ld	a4,8(a5)
    80006830:	00275783          	lhu	a5,2(a4)
    80006834:	2785                	addiw	a5,a5,1
    80006836:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000683a:	0330000f          	fence	rw,rw

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000683e:	100017b7          	lui	a5,0x10001
    80006842:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006846:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    8000684a:	00021917          	auipc	s2,0x21
    8000684e:	dce90913          	addi	s2,s2,-562 # 80027618 <disk+0x128>
  while(b->disk == 1) {
    80006852:	4485                	li	s1,1
    80006854:	01079c63          	bne	a5,a6,8000686c <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006858:	85ca                	mv	a1,s2
    8000685a:	8552                	mv	a0,s4
    8000685c:	ffffc097          	auipc	ra,0xffffc
    80006860:	a52080e7          	jalr	-1454(ra) # 800022ae <sleep>
  while(b->disk == 1) {
    80006864:	004a2783          	lw	a5,4(s4)
    80006868:	fe9788e3          	beq	a5,s1,80006858 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    8000686c:	f9042903          	lw	s2,-112(s0)
    80006870:	00290713          	addi	a4,s2,2
    80006874:	0712                	slli	a4,a4,0x4
    80006876:	00021797          	auipc	a5,0x21
    8000687a:	c7a78793          	addi	a5,a5,-902 # 800274f0 <disk>
    8000687e:	97ba                	add	a5,a5,a4
    80006880:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006884:	00021997          	auipc	s3,0x21
    80006888:	c6c98993          	addi	s3,s3,-916 # 800274f0 <disk>
    8000688c:	00491713          	slli	a4,s2,0x4
    80006890:	0009b783          	ld	a5,0(s3)
    80006894:	97ba                	add	a5,a5,a4
    80006896:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000689a:	854a                	mv	a0,s2
    8000689c:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800068a0:	00000097          	auipc	ra,0x0
    800068a4:	b5a080e7          	jalr	-1190(ra) # 800063fa <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800068a8:	8885                	andi	s1,s1,1
    800068aa:	f0ed                	bnez	s1,8000688c <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800068ac:	00021517          	auipc	a0,0x21
    800068b0:	d6c50513          	addi	a0,a0,-660 # 80027618 <disk+0x128>
    800068b4:	ffffa097          	auipc	ra,0xffffa
    800068b8:	438080e7          	jalr	1080(ra) # 80000cec <release>
}
    800068bc:	70a6                	ld	ra,104(sp)
    800068be:	7406                	ld	s0,96(sp)
    800068c0:	64e6                	ld	s1,88(sp)
    800068c2:	6946                	ld	s2,80(sp)
    800068c4:	69a6                	ld	s3,72(sp)
    800068c6:	6a06                	ld	s4,64(sp)
    800068c8:	7ae2                	ld	s5,56(sp)
    800068ca:	7b42                	ld	s6,48(sp)
    800068cc:	7ba2                	ld	s7,40(sp)
    800068ce:	7c02                	ld	s8,32(sp)
    800068d0:	6ce2                	ld	s9,24(sp)
    800068d2:	6165                	addi	sp,sp,112
    800068d4:	8082                	ret

00000000800068d6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068d6:	1101                	addi	sp,sp,-32
    800068d8:	ec06                	sd	ra,24(sp)
    800068da:	e822                	sd	s0,16(sp)
    800068dc:	e426                	sd	s1,8(sp)
    800068de:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068e0:	00021497          	auipc	s1,0x21
    800068e4:	c1048493          	addi	s1,s1,-1008 # 800274f0 <disk>
    800068e8:	00021517          	auipc	a0,0x21
    800068ec:	d3050513          	addi	a0,a0,-720 # 80027618 <disk+0x128>
    800068f0:	ffffa097          	auipc	ra,0xffffa
    800068f4:	348080e7          	jalr	840(ra) # 80000c38 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068f8:	100017b7          	lui	a5,0x10001
    800068fc:	53b8                	lw	a4,96(a5)
    800068fe:	8b0d                	andi	a4,a4,3
    80006900:	100017b7          	lui	a5,0x10001
    80006904:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    80006906:	0330000f          	fence	rw,rw

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    8000690a:	689c                	ld	a5,16(s1)
    8000690c:	0204d703          	lhu	a4,32(s1)
    80006910:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    80006914:	04f70863          	beq	a4,a5,80006964 <virtio_disk_intr+0x8e>
    __sync_synchronize();
    80006918:	0330000f          	fence	rw,rw
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000691c:	6898                	ld	a4,16(s1)
    8000691e:	0204d783          	lhu	a5,32(s1)
    80006922:	8b9d                	andi	a5,a5,7
    80006924:	078e                	slli	a5,a5,0x3
    80006926:	97ba                	add	a5,a5,a4
    80006928:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000692a:	00278713          	addi	a4,a5,2
    8000692e:	0712                	slli	a4,a4,0x4
    80006930:	9726                	add	a4,a4,s1
    80006932:	01074703          	lbu	a4,16(a4)
    80006936:	e721                	bnez	a4,8000697e <virtio_disk_intr+0xa8>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006938:	0789                	addi	a5,a5,2
    8000693a:	0792                	slli	a5,a5,0x4
    8000693c:	97a6                	add	a5,a5,s1
    8000693e:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006940:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006944:	ffffc097          	auipc	ra,0xffffc
    80006948:	9ce080e7          	jalr	-1586(ra) # 80002312 <wakeup>

    disk.used_idx += 1;
    8000694c:	0204d783          	lhu	a5,32(s1)
    80006950:	2785                	addiw	a5,a5,1
    80006952:	17c2                	slli	a5,a5,0x30
    80006954:	93c1                	srli	a5,a5,0x30
    80006956:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000695a:	6898                	ld	a4,16(s1)
    8000695c:	00275703          	lhu	a4,2(a4)
    80006960:	faf71ce3          	bne	a4,a5,80006918 <virtio_disk_intr+0x42>
  }

  release(&disk.vdisk_lock);
    80006964:	00021517          	auipc	a0,0x21
    80006968:	cb450513          	addi	a0,a0,-844 # 80027618 <disk+0x128>
    8000696c:	ffffa097          	auipc	ra,0xffffa
    80006970:	380080e7          	jalr	896(ra) # 80000cec <release>
}
    80006974:	60e2                	ld	ra,24(sp)
    80006976:	6442                	ld	s0,16(sp)
    80006978:	64a2                	ld	s1,8(sp)
    8000697a:	6105                	addi	sp,sp,32
    8000697c:	8082                	ret
      panic("virtio_disk_intr status");
    8000697e:	00002517          	auipc	a0,0x2
    80006982:	daa50513          	addi	a0,a0,-598 # 80008728 <etext+0x728>
    80006986:	ffffa097          	auipc	ra,0xffffa
    8000698a:	bda080e7          	jalr	-1062(ra) # 80000560 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
