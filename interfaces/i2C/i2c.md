# I2C Bus
[manual](AN10216.pdf)
- Only two pins are required
- Each device have a unique address
- Multimaster and Collision detection
- 50ms Filtering
```lua

SCL --- 
SDA ---

```
| Start Bit (1) | Address (7bit) | W/R (1bit) | Data | Ack | 
|:--|:--|--|:--|:--
![alt text](images.png)
## Procedure

- Wait untill the bus is free (SDA and SDL are both high)
- The Master then Generate the clock, and before the clock go low, the SDA should be lowered.
- This convention should be followed. The transition of SDA is only allowed when the clock is low.
- The data is read when the clock is changed from low to high

- Then the master will put the adress on the bus (7bit) + Read/write bit. By that time all the slaves should be listening.
- When a slave get its address, it says I'm here by lowering the SDA Line and the master will listen to that.
- After this successfull handshake, The master or slave will put data on the SDA and the other one will put ack bit while the sender listens.
- The Comms is stopped by pulling the SDA to high before clock is high
![alt text](36685.png)

## Voltage Thresholds
- All signals above 70% of Vdd is considered HIGH

- All signals below 30% of Vdd is considered LOW

## Rise time and fall time limitations
![alt text](image.png)
