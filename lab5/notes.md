* 1. Что происходит при прерывании скрипта text-trap.sh? Объясните, почему.
```
Предварительно был установлен обработчик для сигнала SIGINT с помощью trap. Поэтому
при нажатии Ctrl+C процессу отпраляется SIGINT, и программа завершается,
выводя сообщение о выходе.
```
* 2. Напишите, по какой причине выводы команды ls -l /proc/self и ls -l /proc/$$ отличаются?
```  
self - PID процесса ls 
$$ - PID оболочки bash
```
* 4. Напишите, какие дескрипторы в выводе команды ls -l /proc/self/fd отвечают за stdin, stdout, stderr.
```
0 - stdin, 1 - stdout, 2 -stderr
```
* 5. Что происходит с дескрипторами при перенаправлении потоков stdout и stderr в файлы при выполнении команды ls -l /proc/self/fd > /tmp/ls.out 2> /tmp/ls.err?
```  
Происходит перенаправление потоков в соответствующие файлы,
а соответсвкнно и переназначение дескрипторов.
```
* 6. Запишите эту же команду, добавив к ней перенаправление потока stdin. Что изменилось?
```
ls -l /proc/self/fd < /tmp/ls.in > /tmp/ls.out 2> /tmp/ls.err
При отсутствии /tmp/ls.in сообщение об ошибке запишется в /tmp/ls.err
В /tmp/ls.out первая строчка изменится на 
lr-x------. 1 root root 64 Dec  1 00:25 0 -> /tmp/ls.in
А стандартный ввод будет перенаправлен из файла /tmp/ls.in
```
* 7. Какой эффект наблюдается при выполнении команды exec ps -l?
```
Текущий процесс изменится на ps -l. После его завершения управление возвращается к bash.
```
* 8. Что означает pos при выводе содержимого файла /proc/$$/fdinfo/3?
```
Текущая позиция указателя чтения-записи в файле процесса оболочки bash.
```
* 9. Существует ли возможность читать содержимое файла test.out даже после его удаления? Почему так происходит?
```
Да, существует. Если записать что-то в файл test.out через ранее открытый дескриптор,
то мы сможем увидеть записанные данные после удаления файла, тк файл не будет удален,
пока не будут закрыты все дескрипторы указывающие на него (пока не будут удалены
все жесткие ссылки).
```
