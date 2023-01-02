module betterc.interfaces;

template getParams (alias fn) 
{
	static if ( is(typeof(fn) params == __parameters) )
    	alias getParams = params;
}

enum isMethodImplemented(T, string member, FuncType)()
{
    bool ret;
    static foreach(overload; __traits(getVirtualMethods, T, member))
        if(is(typeof(overload) == FuncType) && !__traits(isAbstractFunction, overload))
            ret = true;
    return ret;
}


T New(T, Args...)(Args args)
{
    import core.stdc.stdlib:malloc;
    import core.lifetime:emplace;
    align(__traits(classInstanceAlignment, T))
	void[] baseMem = malloc(__traits(classInstanceSize, T))[0..__traits(classInstanceSize, T)];

    T ret = cast(T)baseMem.ptr;
    emplace!T(ret, args);
    return ret;
}

void Destroy(T)(ref T target)
{
    import core.stdc.stdlib:free;
    destroy(target);
    free(cast(void*)target);
    target = null;
}



///Needs correct linkage for working with D custom types such as string
package string linkage(alias sym)()
{ 
    return "extern ("~__traits(getLinkage, sym)~")";
}

///Attributes such as `ref` and `const` modify the return type, so, they need to exist
package string attributes(alias sym)()
{
    string ret = "";
    static foreach(attr; __traits(getFunctionAttributes, sym))
        ret~= attr~ " ";
    return ret;
}

enum GenCPPInterface(Self, itf) =  ()
{
    string ret = "class _" ~ __traits(identifier, itf)~"Impl : itf {" ~ q{ extern(C++):
            Self self;
            this(Self self){this.self = self;}
            };
    
    import std.traits;
    static foreach(fn; __traits(allMembers, itf))
    {{
        string mem = "__traits(getMember, itf, \""~ fn~ "\")";
        string retT = "ReturnType!("~mem~")";
        string params = "getParams!("~mem~")";

        ret~= linkage!(__traits(getMember, itf, fn)) ~ " "  ~  attributes!(__traits(getMember, itf, fn)) ~" override " ~ retT ~ " " ~ fn ~ ("("~params~")") ~ "{"~
            "return (cast(Self)self)."~fn~"(__traits(parameters));}";
    }}
    return ret ~ "}";
}();

extern(C++) abstract class CppObject
{
    this(){initialize();}
    void initialize(){}
}

extern(C++) class CppInterface(Self, Interfaces...) : CppObject
{
    static foreach(itf; Interfaces)
    {
        mixin(q{private itf },  ("_"~__traits(identifier, itf)) ~ ";");
    }
        
    override void initialize()
    {
        import std.traits:ReturnType;
        static foreach(itf; Interfaces)
        {
            mixin(GenCPPInterface!(Self, itf));
            mixin( ("_"~__traits(identifier, itf)) ~(" =  New!(_" ~__traits(identifier, itf) ~ "Impl)(cast(Self)this);"));
        }
    }
    
    
    T getInterface(T)()
    {
        static if(__traits(hasMember, Self, "_"~T.stringof))
            return mixin("_",T.stringof);
        else static if(is(T == Self))
			return cast(Self)this;
		else return null;
    }

	~this()
	{
		import core.stdc.stdlib;
		static foreach(itf; Interfaces)
		{{
			alias mem = __traits(getMember, Self, "_"~itf.stringof);
			destroy(mem);
			free(cast(void*)mem);
            mem = null;
		}}
	}
}


extern(C++) class CppExtend(Self, Target, Interfaces...) : CppObject
{

    mixin(q{private Target } ~ ("_"~__traits(identifier, Target))~";");
    static foreach(itf; Interfaces)
    {
        mixin(q{private itf },  ("_"~__traits(identifier, itf)) ~ ";");
    }
        
    override void initialize()
    {
        import std.traits:ReturnType;
        mixin("_"~__traits(identifier, Target)) = New!Target();
        static foreach(itf; Interfaces)
        {
            mixin(GenCPPInterface!(Self, itf));
            mixin( ("_"~__traits(identifier, itf)) ~(" =  New!(_" ~__traits(identifier, itf) ~ "Impl)(cast(Self)this);"));
        }
    }
    
    
    T getInterface(T)()
    {
        static if(is(T == Target))
            return mixin("_"~__traits(identifier, Target));
        else static if(__traits(hasMember, Self, "_"~T.stringof))
            return mixin("_",T.stringof);
        else static if(is(T == Self))
			return cast(Self)this;
		else return mixin("_"~__traits(identifier, Target)).getInterface!T;
    }

    //Forward base class methods
    import std.traits:ReturnType;
    static foreach(mem; __traits(allMembers, Target))
    {
        static foreach(ov; __traits(getVirtualMethods, Target, mem))
        {
            static if(!__traits(hasMember, Self, mem) || !isMethodImplemented!(Self, mem, typeof(ov)))
            {
                mixin(linkage!ov ~" " ~attributes!(ov)~ " ReturnType!(ov) " ~ mem ~ "(getParams!(ov))"~
                "{ return " ~ ("_"~__traits(identifier, Target)) ~ "." ~mem ~ "(__traits(parameters));}");
            }
        }
    }

	~this()
	{
		import core.stdc.stdlib;
        {
            alias mem = __traits(getMember, Self, "_"~__traits(identifier, Target));
            destroy(mem);
            free(cast(void*)mem);
            mem = null;
        }
		static foreach(itf; Interfaces)
		{{
			alias mem = __traits(getMember, Self, "_"~itf.stringof);
			destroy(mem);
			free(cast(void*)mem);
            mem = null;
		}}
	}
}