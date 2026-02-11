# I2C Dynamic Role Switching Project Documentation (

**Target:** STM32H755ZI (NUCLEO)
**Peripherals:** I2C2, UART5, BSP Button (EXTI), BSP LEDs, Dual-Core Boot Sync
**Core:** Cortex-M7
**Mode:** Runtime Role Switching (Slave ↔ Master)

---

## System Overview

This firmware implements a **dynamic I2C role-switching system**.

Unlike the previous static role selection at startup, this version:

* Boots as **SLAVE**
* Switches to **MASTER dynamically** when receiving a UART command
* Sends an I2C command to another slave
* Returns automatically to **SLAVE mode**

---

## Role Architecture

```c
typedef enum{
  ROLE_SLAVE = 0,
  ROLE_MASTER
} DeviceRole_t;

volatile DeviceRole_t deviceRole = ROLE_SLAVE;
```

### Default Behavior

* System boots as `ROLE_SLAVE`
* I2C is initialized in **slave mode**
* UART interrupt is enabled
* I2C Listen mode is enabled

---

## Communication Flow

### Step 1 — Button Press

* USER button interrupt triggers:

```c
void BSP_PB_Callback(Button_TypeDef btn)
{
    HAL_UART_Transmit(&huart5,"myLedOn",7,HAL_MAX_DELAY);
}
```

This sends:

```
"myLedOn"
```

over **UART5**

---

### Step 2 — UART Reception

```c
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
  if (strncmp(rxBuff,"myLedOn",7) == 0)
  {
    if (deviceRole == ROLE_SLAVE)
    {
        deviceRole = ROLE_MASTER;
        printf("Switching to MASTER mode\n");
    }
  }

  HAL_UART_Receive_IT(&huart5,rxBuff,sizeof(rxBuff));
}
```

If the received message matches `"myLedOn"`:

* Device switches from **SLAVE → MASTER**
* UART reception is re-armed

---

### Step 3 — Master Transmission

Inside the main loop:

```c
if (deviceRole == ROLE_MASTER)
{
    HAL_I2C_DeInit(&hi2c2);
    HAL_Delay(10);

    I2C_Init_Master();
    Send_Message_To_Slave();

    HAL_I2C_DeInit(&hi2c2);
    HAL_Delay(10);

    deviceRole = ROLE_SLAVE;
    I2C_Init_Slave();
}
```

The device:

1. Deinitializes I2C
2. Reconfigures as MASTER
3. Sends `0x01`
4. Returns to SLAVE mode

---

## I2C Configuration

### Slave Address Definitions

```c
#define MY_SLAVE_ADDRESS     0x3C
#define OTHER_SLAVE_ADDRESS  0x3C
```

---

## I2C Slave Initialization

```c
void I2C_Init_Slave(void)
{
    hi2c2.Init.OwnAddress1 = MY_SLAVE_ADDRESS << 1;
    HAL_I2C_Init(&hi2c2);
    HAL_I2C_EnableListen_IT(&hi2c2);
}
```

### Key Features

* 7-bit addressing
* Listen interrupt enabled
* Error handling added
* Debug prints added

---

## I2C Master Initialization

```c
void I2C_Init_Master(void)
{
    hi2c2.Init.OwnAddress1 = 0;
    HAL_I2C_Init(&hi2c2);
}
```

### Master Transmission

```c
void Send_Message_To_Slave(void)
{
    uint8_t msg = 0x01;

    HAL_I2C_Master_Transmit(
        &hi2c2,
        OTHER_SLAVE_ADDRESS << 1,
        &msg,
        sizeof(msg),
        1000
    );
}
```

✔ Uses timeout instead of `HAL_MAX_DELAY`
✔ Checks transmission status
✔ Debug prints included

---

## I2C Interrupt Flow (Slave Mode)

### Address Match Callback

```c
void HAL_I2C_AddrCallback(...)
{
    HAL_I2C_Slave_Seq_Receive_IT(
        hi2c,
        &rxBuffer,
        1,
        I2C_FIRST_AND_LAST_FRAME
    );
}
```

Triggered when:

* Master addresses this slave
* Direction = Master → Slave

---

### Receive Complete Callback

```c
void HAL_I2C_SlaveRxCpltCallback(...)
{
    if (rxBuffer == 0x01)
    {
        BSP_LED_Toggle(LED_GREEN);
    }

    HAL_I2C_EnableListen_IT(hi2c);
}
```

Behavior:

* Prints received data
* Toggles GREEN LED if `0x01`
* Re-enables Listen mode

---

### Listen Complete Callback

```c
void HAL_I2C_ListenCpltCallback(...)
{
    HAL_I2C_EnableListen_IT(hi2c);
}
```

Handles STOP condition detection.

---

### Error Callback

```c
void HAL_I2C_ErrorCallback(...)
{
    printf("I2C ERR = 0x%08lX\n", hi2c->ErrorCode);

    if (deviceRole == ROLE_SLAVE)
    {
        HAL_I2C_EnableListen_IT(hi2c);
    }
}
```

✔ Prints error code
✔ Attempts recovery in SLAVE mode

---

## Peripheral Summary

| Peripheral | Purpose                       |
| ---------- | ----------------------------- |
| UART5      | Command transport ("myLedOn") |
| I2C2       | Master/Slave communication    |
| BSP Button | Trigger UART transmission     |
| BSP LEDs   | Visual feedback               |
| HSEM       | Dual-core synchronization     |

---

## Dual-Core Boot Synchronization

This project includes:

```c
#define DUAL_CORE_BOOT_SYNC_SEQUENCE
```

Sequence:

1. Wait for CPU2 ready
2. Take hardware semaphore
3. Release semaphore to wake CM4
4. Confirm wake-up

Ensures safe startup on STM32H755 dual-core device.

---

## Debug Improvements (Compared to Basic Version)

✔ Added initialization result checks
✔ Added transmission status validation
✔ Added timeout protection
✔ Added error recovery
✔ Added STOP detection handling
✔ Added proper sequential slave API usage
✔ Added debug print tracing
✔ Increased I2C reconfiguration delay
✔ Fixed incorrect `\n` usage
✔ Corrected format specifiers

---

## Runtime Behavior Summary

| State        | Action                      |
| ------------ | --------------------------- |
| Boot         | SLAVE mode                  |
| Button Press | Sends `"myLedOn"` over UART |
| UART RX      | Switch to MASTER            |
| MASTER       | Send `0x01` via I2C         |
| Slave Device | Toggle GREEN LED            |
| After Send   | Return to SLAVE             |

---

## Communication Protocol

### UART Command

```
"myLedOn"
```

### I2C Command

```
0x01 → Toggle LED
```

## Full source code 
[main.c](main.c)