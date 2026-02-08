# Boot Sequence
## 1. Power Applied / Reset Released

- VDD and other supplies rise.
- Internal POR/BOR circuits hold the MCU in reset.
- Once voltages stabilize, reset is released.

Nothing executes yet.

---

## 2. D3 Power Domain Turns ON (Always First)

The D3 domain contains:

- Reset logic  
- RCC (clock controller)  
- Boot configuration logic  
- Backup domain  

So D3 must come up before anything else.

---

## 3. RCC Starts With Safe Default Clocks

RCC initializes minimal clocking:

- Internal HSI oscillator enabled  
- PLLs OFF  
- CPU clock sourced from HSI  
- Prescalers at reset values  

This provides just enough clock to continue boot.

---

## 4. Boot Configuration Is Sampled

RCC reads:

- BOOT0 pin  
- BOOT_ADD0 / BOOT_ADD1  
- Option bytes:
  - BOOTC1
  - BOOTC2  

Located in:

```

RCC → GCR register

```

These determine which memory is mapped to address `0x00000000`.

---

## 5. Boot Memory Aliasing

Based on boot configuration, address `0x00000000` is mapped to:

- User Flash (normal boot)
- System Memory (ST bootloader)
- SRAM (debug / RAM boot)

This is address remapping, not physical movement.

---

## 6. Cortex-M7 Core Released From Reset

The CM7 core starts:

- MSP loaded from `0x00000000`
- PC loaded from `0x00000004`

Vector table is fetched.

CM7 begins execution.

CM4 remains in reset.

---

## 7. System Memory (If Selected)

If System Memory was chosen:

- ST internal bootloader runs
- Waits for UART / USB / CAN / SPI

If Flash boot is selected, this step is skipped.

---

## 8. User Startup Code Begins

`Reset_Handler` executes:

- Stack initialized  
- `.data` copied to RAM  
- `.bss` cleared  

Then calls:

```

SystemInit()

```

---

## 9. SystemInit() Configures Main Clock Tree

Typical operations:

- Enable HSE (if used)
- Configure PLLs
- Switch SYSCLK from HSI → PLL
- Configure Flash latency
- Enable caches
- Configure voltage regulators

MCU now runs at full speed.

---

## 10. D1 and D2 Domains Enabled

Firmware enables:

- D1 → CPU + AXI
- D2 → GPIO, DMA, peripherals

Peripherals become operational.

---

## 11. Cortex-M4 Core (Optional)

If dual-core project:

- CM7 releases CM4 via RCC
- CM4 loads its vector table
- CM4 begins execution

Otherwise CM4 stays in reset.

---

## 12. main()

Finally:

```

main()

```

Your application starts.

---

## Compact Flow


Power On
↓
POR/BOR
↓
D3 domain ON
↓
RCC safe clocks (HSI)
↓
BOOT pins + BOOTC1/2 sampled
↓
0x00000000 remapped
↓
CM7 released
↓
Vector fetch
↓
Reset_Handler
↓
SystemInit()
↓
D1/D2 ON
↓
(Optional CM4 boot)
↓
```
main()
```
