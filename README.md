# 3AM

When you're still up at three in the morning because you're ~~too hyper~~ a night owl.

---

## Usage

```plain
Usage: [OPTIONS] [-- [CMD]]

Prevents the system from sleeping

Options:
  -d, --display-wake   Keep display active
  -s, --ac-wake        (On AC) Keep system active if lid closed or sleep requested
  -h, --help           Display this help message

Options when CMD is present:
  -v, --verbose        Output status information (optionally uses fd=3)
```

---

## Examples

* `3am`
  * Keep system running (display can turn off)
* `3am -d`
  * Keep system running (display will stay on)
* `3am --ac-wake -- /tmp/processData.sh /tmp/dataToBeProcessed.txt`
  * Run `/tmp/processData.sh /tmp/dataToBeProcessed.txt`
  * If the device is connected to power, only turn off display if sleep mode is entered
* `3am --ac-wake -v -- /tmp/processData.sh /tmp/dataToBeProcessed.txt`
  * Run `/tmp/processData.sh /tmp/dataToBeProcessed.txt`
  * If the device is connected to power, only turn off display if sleep mode is entered
  * This will output status information
* `3am --ac-wake -v -- /tmp/processData.sh /tmp/dataToBeProcessed.txt 3>/tmp/output.txt`
  * Run `/tmp/processData.sh /tmp/dataToBeProcessed.txt`
  * If the device is connected to power, only turn off display if sleep mode is entered
  * This will output status information into `/tmp/output.txt`

---

## Debugging

* `pmset -g assertions`
* `pmset -g assertionslog`
