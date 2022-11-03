# CacheUtil

**A utility for inspecting CACHE.DAT files for the Prodigy Reception System**

## Installation

1. Install elixir per https://elixir-lang.org/install.html
2. Get dependencies with `mix deps.get`
3. Build the script with `mix escript.build`
4. Copy the resulting binary (`cacheutil`) to the path of your choice, or run `mix escript.install` and add `~/.mix/escripts` to your `PATH`
5. Run `cacheutil` without arguments for usage

## Notes

- CACHE.DAT utilizes 128 byte blocks with allocations managed in RAM during Reception System execution.  Thus, extraction of objects from CACHE.DAT is less robust than STAGE.DAT.  It is done by inspecting looking for an object header at the beginning of each block, then minimally validating the segments within the object.
- This has not been tested on STAGE.DAT from the Macintosh version of the reception system.
## Example Usages

### Information on a particular STAGE.DAT

```
% cacheutil info CACHE.DAT 
Source: /tmp/CACHE.DAT
```

### List files matching a pattern

```
% cacheutil dir CACHE.DAT --glob "*.LDR"
Source: /tmp/CACHE.DAT

Name          Seq Type # in Set Length Version Storage     Version Check
------------  --- ---- -------- ------ ------- ----------- -------------
ZL000005.LDR    0    8        1    918       0 Cache       Yes
BY000041.LDR    0    8        1    567       0 Cache       Yes
FSA0A101.LDR    0    8        1    647       0 Cache       Yes
R2000107.LDR    0    8        1    306       0 Cache       Yes
6U00038B.LDR    0    8        1    471       0 Cache       Yes
AW000083.LDR    0    8        1    402       0 Cache       Yes
BQ000047.LDR    0    8        1    407       0 Cache       Yes
IBH0A107.LDR    0    8        1    591       8 Cache       Yes
76000013.LDR    0    8        1    558       0 Cache       Yes
TS000134.LDR    0    8        1    605       0 Cache       Yes
```

The column meanings are as follows:
#### Name
The name of the object as encoded in the first 11 bytes.  The "." is not included with the encoded name.

#### Seq
This is the sequence of item within the set of items.  For example, the News Headlines `NH00A000.B` may be a set of
99 items, so this sequence may range from 1 to 99.

#### Type
This is the type of object, in hexadecimal, as shown in the example for `list-object-types` below.

#### # in Set
This is the number of items in the set, as described in Seq above.  Note: The size may be 0, but the sequence 1.

#### Version
This is the numeric version of the object.  The reception system sends this to the server when seeking object updates.

#### Storage
This indicates the eligibility of the Object for storage within, or eviction from the various reception system caches:

* ##### Cache
    * This item is generally eligible to only be stored in the `CACHE.DAT` file, which is overwritten every session.  It can be stored in `STAGE.DAT`, but will be evicted in deference to a newly retrieved file with Stage candidacy.
* ##### None
    * This item is generally only eligible to be memory resident, or embedded within another object that has Stage or Cache candidacy.
* ##### Stage
    * This item is eligible for retention in the `STAGE.DAT` file, which persists across sessions
* ##### Required
    * This item is required at all times, and is never eligible for eviction from `STAGE.DAT`
* ##### Large Stage
    * This item is eligible only for the larger `STAGE.DAT` created by RS 8+

#### Versioning

* ##### Yes
    * The object is always version checked when first accessed during a session.
* ##### No
    * The object is only version checked when the Reception Control Object `ITRC0001.D` version is incremented with respect to the one stored within `STAGE.DAT`





### Recursive export all program files with names matching a particular pattern

```
% cacheutil export CACHE.DAT --glob "Z*.*" --recurse --dest ./out
% ls out
ZL000005.LDR ZPA00000.PG  ZPA0A000.B   ZPC0A053.B   ZPC0A054.B
```

### List Object Types
The object type corresponds to the "type" column in the directory listing.

```
% cacheutil list-object-types
Object Types

0x0 - Page Format Object
0x4 - Page Template Object
0x8 - Page Element Object
0xC - Program Object
0xE - Window Object
```
