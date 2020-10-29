# GMVitalizer
GMVitalizer is a tool that converts GMS2 projects to GMS1.

As per name, perhaps the only good use case for this is PS Vita development, as Vita support was dropped in GMS2 (for good reasons).

The tool will convert most project contents to GMS1 format, convert most of GML changes back, and convert/create compatibility scripts for most of GMS2-specific functions. 

## Using
You give the tool a path to the YYP project and to the resulting GMX project, along with any optional arguments.

Running the standalone version might be as following:
```bat
GMVitalizer my_project/my_project.yyp my_project.gmx/my_project.project.gmx
```
or running the Neko version:
```bat
neko gmvitalizer.n my_project/my_project.yyp my_project.gmx/my_project.project.gmx
```
Optional arguments are as following:
- `--rules filepath`: Uses a custom rules-file instead of default rules.gml  
  Example: `--rules myrules.gml`
- `--bkrx regexp`: Specifies a regular expression for telling apart background-sprites from regular sprites.
  If provided, bottom-layer backgrounds will become actual GMS1 room backgrounds.  
  You can also specify multiple of these.
  Example: `--bkrx ^bck_`.
- `--nort type`, `--nort type1,type2`: Skips specific operations, such as  
  - `datafilesrc`: copying included files
  - `soundsrc`: audio file sources
  - `spritesrc`: sprite PNGs
  - `backgroundsrc`: background PNGs
  
  This can save time when re-running the conversion on same project with updated code/rules.
- `-D name`, `-D name=value`: Specifies a custom parameter for use in ruleset filters (see below)

## Rulesets
Ruleset files are the core of GMVitalizer.

The default rules can be found in `rules.gml` and can be tweaked to fit specific needs.

### Remap
Essentially sets up a rule for converting one snippet of code into other snippet of code,
```js
remap input_code -> output_code
remap(flag) input_code -> output_code
remap(flag1,flag2) input_code -> output_code
```
Both `input_code` and `output_code` can contain expression matchers, which can be the following:
- `$0`..`$9`: matches a balanced value, either until subsequent chunk of code in input if the last item, or until the apparent delimiter (e.g. a semicolon or the next statement)
- `${type}`, `${0:type}`..`${9:type}`: matches a special expression type. If index is not specified but needed, index 0 is used.

The following special types are supported:
- `${set}`: matches `=`, but does not match `==`.  
  Prevents `some = $1` matching `some == "hi"`.  
  Also see `stat` flag.
- `${op}`: matches a binary operator (`+`, `-`, `*`, etc.).  
  If used in output for an expression that was an assignment operator, converts it into a binary operator.
- `$(aop)`: matches an assignment operator (`+=`, `-=`, etc.).  
  Does NOT match set `=` alone.  
  Similarly, can convert a binary operator into an assignment operator when used in output.
  
`input_code` should start with an identifier (e.g. a function name), or `$0.ident`..`$9.ident`, in which case it will match field access and store the preceding expression.

Flags can be the following:
- `stat`: Ensures that input is a statement.
- `expr`: Ensures that input is NOT a statement.
- `self`: Ensures that input is not preceded by field access (`obj.`).  
  Allows to define different match rules for `obj.image_speed` / `image_speed`.

Examples:
```js
// simple
remap gpu_set_fog -> d3d_set_fog

// unwraps string_hash_to_newline calls
remap string_hash_to_newline($1) -> ($1)

// replaces two-argument instance_destroy with instance_destroy_ext
remap instance_destroy($1, $2) -> instance_destroy_ext($1, $2)

// `q.image_speed += 1` -> `image_speed_post(image_speed_pre(q) + 1)`
remap(stat) $1.image_speed ${2:aop} $3 -> image_speed_post(image_speed_pre($1) ${2:op} $3)
// `q.image_speed = 1` -> `image_speed_set(q, 1)
remap(stat) $1.image_speed ${set} $2 -> image_speed_set($1, $2)
// a = `q.image_speed` -> a = `image_speed_get(q)`
remap(expr) $1.image_speed -> image_speed_get($1)

// for the following, self-flag ensures that they don't clash with preceding set
remap(self,stat) image_speed ${1:aop} $2 -> image_speed_post(image_speed_pre(id) ${1:op} $2)
remap(self,stat) image_speed ${set} $1 -> image_speed_set(id, $1)
remap(self,expr) image_speed -> image_speed_get(id)
```

### Imports
Sets up a rule to conditionally or unconditionally import resources from the "compatibility" project or "compatibility" directory.
```js
import name
import name1,name2
import name if ident
import name if ident1 or ident2
```
For conditional import, resource(s) will be imported if identifier(s) are referenced anywhere in the source code;  
For the most time, you will not have to write import rules by hand, since referencing the resource by direct name imports it, and a resource will auto-import its dependencies (incl. object parents) as result.

### Conditions
If you desire to give multiple remaps/imports the same condition, there is also conditional compilation of sorts,
```
#if condition-expr
...
#end
// or:
#if condition-expr
...
#else
...
#end
```
condition-expr uses
[hscript](https://github.com/HaxeFoundation/hscript)
with a few predefined globals:

- Standard library: `String`, `StringTools`, `Std`, `Math`, `trace`.
- `defs`: A map containing parameters that you passed via `-D` (e.g. `#if defs["name"]`)
- `gml`: A map that has keys for used GML API entries set (e.g. `#if gml["camera_create"]`)  
  A few configuration-specific entries also end up in here:  
  
  - `sprite_speed`: indicates that the project has sprites with non-default (1 sprite frame per 1 game frame) speeds

For convenience, the interpreter also uses slightly modified boolean evaluation rules:

- Numbers are true-ish if they are not `0`
- Strings are true-ish if they are not `""`
- Object references are true-ish if they are not `null`
- Booleans work as usual

## Building
If you would like to compile from source code, you will need an up to date version of [Haxe](https://haxe.org/) and then either compile via [HaxeDevelop](https://haxedevelop.org/)/FlashDevelop, or compile from command-line/terminal, like so:
```bat
haxe -cp src -neko bin/gmvitalizer.n -main GMVitalizer -lib hscript
```
targeting C++ is generally going to yield higher performance, but less descriptive error messages (unless in debug mode).

You will also need to install `hscript` library if you didn't yet:
```
haxelib install hscript
```

## Limitations
This is by no means a comprehensive list, just things that _definitely_ don't work
- Room inheritance
- Variable definitions
- Any 2.3+ syntax (object literals, exception handling, function literals)
- Compatibility tile layers
- Asset layers (the GMS2-specific kind where you put sprites on a layer without instances/tiles)

The following are the known caveats:
- Tile animations are implemented by cycling indexes, GMS2 doesn't change indexes.  
  (see `obj_gmv_layer_tilemap`)
- Some of the Haxe source code is originally auto-generated (see [json2typedef](https://github.com/YellowAfterlife/json2typedef), [gmx2hxgen](https://bitbucket.org/yal_cc/gmx2hxgen)) and thus may look unusual.

## Credits

- Written/maintained by Vadim "YellowAfterlife" Dyachenko.
- Written in [Haxe](https://haxe.org/).
- Uses [hscript](https://github.com/HaxeFoundation/hscript) for conditionals.
- Uses some snippets from [GMEdit](https://github.com/GameMakerDiscord/GMEdit/) for project processing.

## Special thanks

- [Ratalaika Games S.L.](http://ratalaikagames.com/), for funding majority of development of this project.  
  I probably wouldn't get around to doing this otherwise.
