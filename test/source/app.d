import betterc.interfaces;

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
