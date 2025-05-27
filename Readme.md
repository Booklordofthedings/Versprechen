# **Versprechen** - A threading library written in Beef

```cs
var e = Eat(504, 1500);
e.Then(new (v) =>
	{
		if (v case .Ok(let val))
			Console.WriteLine(val);
	});

Console.WriteLine("Doing some calculations here");

var res = e.Await();
switch (res)
{
	case .Err:
	case .Ok(let val):
		Console.WriteLine(val + 2);
}
delete e;
```
