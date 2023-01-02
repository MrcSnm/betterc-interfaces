# betterc-interfaces
Provides interface compatibility to D -betterC flag. Poymorphism and dynamic casts on betterC!


## What it can do
- Implement multiple interfaces
- Dynamic casts
- Inheritance

## Limitations

- Can't define a new destructor
- Usage of `interfaces` is done via `abstract class` instead of interface itself. This happens because simply by using `interface` keyword, D refuses to build.
- `opCast` can't be defined as of now, use `getInterface!T`. This happens because opCast breaks `emplace`, so, you won't be able to allocate a new class.
- If your constructor has parameters, you won't be able extend that class with `CppExtend` it (unless you do a default params constructor)
- Needs to call getInterface! for functions accepting super class when using `CppExtend`:

```d
interface IInterfaceA {}
interface IInterfaceB {}
class Test : CppInterface!(Test, IInterfaceA){}
class Test2 : CppExtend!(Test2, Test, IInterfaceB){}
void test(Test t){}

Test2 t = New!Test2();
test(t); //Fails
//Instead, use:
test(t.getInterface!Test);
```

## Example Usage:

```d
extern(C++)
{
	///Interface
	abstract class Printable
	{
		void print();
	}
	///Interface
	abstract class Stringificable
	{
		extern(D) string toString2();
	}


	///New class implementing Printable and Stringificable classes
	class Test : CppInterface!(Test, Printable, Stringificable)
	{
		void print()
		{
			import core.stdc.stdio;
			printf("toString on print function: %s\n", toString2.ptr);
		}
		extern(D) string toString2()
		{
			return __traits(identifier, Test);
		}
	}

	abstract class DoIt
	{
		void doIt();
	}

	///Extend and include new interface
	class Test2 : CppExtend!(Test2, Test, DoIt)
	{
		void doIt()
		{
			import core.stdc.stdio;
			printf("Done it!\n");
		}
	}

	///Simply extend existing class with interface
	class Test3 : Test
	{

	}
}

extern(C) void main()
{
	Test2 t = New!Test2();

	t.print;
	t.doIt();
}
```