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
*Promises as a feature are not exactly consistent between programming languages.  
This Beef implementation takes some inspiration from `rust`.
When you create a promise the function thats passed in will be executed asynchronously by a threadpool.  
Meanwhile the context that started to thread
can continue executing until it calls Await, at which point it will block.*

### API
- **Create(Promise<T, E> p, delegate Result<T, E>(PromiseValue v) func, PoolExecutor executor)** *Attaches the function to be executed asynchronously `func` onto the promise `p` and tells `executor` to execute it*
- **Promise.Resolved** *A non blocking call that returns wether the function is done*
- **Promise.Await() : Result<T, E>** *Blocks the current context until `func` is done, and returns a Result*
-  **OnCleanup(delegate void(Result<T, E>) func)** *This method should be used to cleanup allocations in `func` that need to live beyond its scope*
-  **Then(delegate void(Result<T, E>) func)** *Executes after the `func` is done*
-  **OnErr(delegate void(E) func)** *Executes after the `func` is done. Only when it errored*
-  *OnOk(delegate void(T) func)** *Executes after the `func` is done. Only when its successfull*
