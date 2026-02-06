## Interrupts in STM32H755ZI

Interrupts are like getting a phonecall while listening to music.
- The music stops
- We have to deal with the phonecall (ISR)
- Then we are done with the phone (RET) the music continues playing.

As simple as that!!!

## Types of interrupts in STM32H755ZI
Since this is a dualcore processor, Interrupt should be mapped to one core and handled by that.

Any GPIO can be used as an external interrupts ```EXT1```.
For research, I'll flush out what will we do to setup an inturrupt and then we will research about what is happening inside. We are using HAL (Hardware Abstraction Layer) provided by the manufacture.

- First we will decide which GPIO pin we have to use as ```EXTI```. 
- We setup it as External Interrupt with Falling Edge Triggering.
- Set the context to CM7.
- Then in the **NVIC** tab we enabled the line.
- Then in the code,
```c
void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin)
{

  if(GPIO_Pin == GPIO_PIN_13) {
    counter++;
    if (counter >= NUM_OF_MODS) {
		counter = 0;
	}
    printf("%d\n",counter);
  }
}
```
The HAL_GPIO_EXTI_Callback function is somehow callbacked when the inturrupt happened with the GPIO pin number as parameter.
- We have to find out how.
- So things we have to do:
    - Figure out how the interrupts are wired
    - What is NVIC
    - Were and what calls the function

## Nested Vectored Interrupt Controller (NVIC)
- This is a hardware unit which handles all the exceptions and interrupts like butter.
- It have a programmable priority system
- It is nested. That means A high priority interrupt can interrupt a low priority interrupt. Yes!! Interrupt ka interrupt.
- Since they are vectored, It can Jump to their ISRs quickly. Makes it responsive.
- We'll be back to the vector table stuff later.

## How the inturrupts are wired in H755ZI code

There are 20 (EXTI0 to EXTI19) lines for External Inturrupts in STM32H755ZI. Each can be mapped to GPIO Pins. Here we are using the channel 15 which is mapped to GPIO_PIN_13
in ```bliiiink/CM7/Core/Inc/stm32h7xx_it.h``` there is a function declaration for 
```h
void EXTI15_10_IRQHandler(void);
```
This call back will handle the line 15 EXTI inturrupts.
In the ```c``` file of it we can see the implementation of this function.
```c
/**
  * @brief This function handles EXTI line[15:10] interrupts.
  */
void EXTI15_10_IRQHandler(void)
{
  /* USER CODE BEGIN EXTI15_10_IRQn 0 */

  /* USER CODE END EXTI15_10_IRQn 0 */
  HAL_GPIO_EXTI_IRQHandler(B1_Pin);
  /* USER CODE BEGIN EXTI15_10_IRQn 1 */

  /* USER CODE END EXTI15_10_IRQn 1 */
}
```
- Here we can see that here it calls the ```HAL_GPIO_EXTI_IRQHandler(B1_Pin);``` function.
- Here ths CubeMX will define the B1_Pin which we specified in the ```ioc```. We can see the defenition of it in out main file. We can also see the defenitions of the GPIO port and inturrput handler for the B1 button
```c
#define B1_Pin GPIO_PIN_13
#define B1_GPIO_Port GPIOC
#define B1_EXTI_IRQn EXTI15_10_IRQn
``` 
- Now in the ```stm32h7xx_hal_gpio.c``` file we can see the implemetation of the ```HAL_GPIO_EXTI_IRQHandler``` function.
```c
void HAL_GPIO_EXTI_IRQHandler(uint16_t GPIO_Pin)
{
#if defined(DUAL_CORE) && defined(CORE_CM4)
  if (__HAL_GPIO_EXTID2_GET_IT(GPIO_Pin) != 0x00U)
  {
    __HAL_GPIO_EXTID2_CLEAR_IT(GPIO_Pin);
    HAL_GPIO_EXTI_Callback(GPIO_Pin);
  }
#else
  /* EXTI line interrupt detected */
  if (__HAL_GPIO_EXTI_GET_IT(GPIO_Pin) != 0x00U)
  {
    __HAL_GPIO_EXTI_CLEAR_IT(GPIO_Pin);
    HAL_GPIO_EXTI_Callback(GPIO_Pin);
  }
#endif
}
```
We can see it will call our ISR we defined in the main file that we disussed [here](#types-of-interrupts-in-stm32h755zi).
```c
void HAL_GPIO_EXTI_IRQHandler(uint16_t GPIO_Pin)
{
#if defined(DUAL_CORE) && defined(CORE_CM4)
  if (__HAL_GPIO_EXTID2_GET_IT(GPIO_Pin) != 0x00U)
  {
    __HAL_GPIO_EXTID2_CLEAR_IT(GPIO_Pin);
    HAL_GPIO_EXTI_Callback(GPIO_Pin);
  }
#else
  /* EXTI line interrupt detected */
  if (__HAL_GPIO_EXTI_GET_IT(GPIO_Pin) != 0x00U)
  {
    __HAL_GPIO_EXTI_CLEAR_IT(GPIO_Pin);
    HAL_GPIO_EXTI_Callback(GPIO_Pin);
  }
#endif
}
```
## How interrupts work under hardware
- Each EXTI line ```EXTICR[0..3]