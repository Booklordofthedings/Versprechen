namespace Versprechen;
using Versprechen.Internal;

using System;
using System.Threading;

class Program
{
	public static PoolExecutor executor = new .(6);

	public static void Main()
	{
		/*
		/*
			PromiseAPI:
				Promise<T, E>.Create(object, delegate, executor)
					//Takes in a promise object, the function and the threadpool that the promise is supposed to run on

			Promise.Resolved //Non blocking done check
			Promise.Await : Result<T, E> //Blocks until the promise has been resolved
			Promise.OnCleanup //If the promise allocates memory you need to free it, this can be used for that
			Promise.Then //What to do once the promise has been resolved
			Promise.OnOk //What to do once the promise has been resolved sucesfully
			Promise.OnErr //What to do once the promise has been errored
		*/
		PrintSomeNumbers();
		DoSomethingWhileWaiting();
		DependencyChains();

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
		//Thread.Sleep(3500);
		*/

		LotsOfNumbers();
		LotsOfNumbers();
		LotsOfNumbers();
		LotsOfNumbers();
		LotsOfNumbers();
		LotsOfNumbers();
		LotsOfNumbers();
		LotsOfNumbers();
		LotsOfNumbers();
		LotsOfNumbers();

		delete executor;
	}

	public static void LotsOfNumbers()
	{
		for (var i < 10000)
		{
			Promise<void, void>.Create(.. scope .(), new (v) =>
				{
					if (gRand.Next(0, 255) == 24)
						Console.WriteLine("hit");
					return .Ok;
				}, executor);
		}
	}

	public static void PrintSomeNumbers()
	{
		for (var i < 100)
		{
			Promise<void, void>.Create(.. scope .(), new (v) =>
				{
					//Thread.Sleep(gRand.Next(0, 255));
					Console.WriteLine(i);
					return .Ok;
				}, executor);
		}
	}

	public static void DoSomethingWhileWaiting()
	{
		var largeOperation = Promise<void, void>.Create(.. scope .(), new (v) =>
			{
				//Thread.Sleep(1000);
				Console.WriteLine("Done");
				return .Ok;
			}, executor);

		Console.WriteLine("We have returned");
		largeOperation.Await();
	}

	public static void DependencyChains(int counter = 20)
	{
		Console.WriteLine(scope $"CHAIN: {counter}");
		//Thread.Sleep(100);
		var p = Promise<void, void>.Create(.. scope .(), new (v) =>
			{
				if (counter > 0)
					DependencyChains(counter - 1);
				return .Ok;
			}
			, executor);
		p.Await();
	}

	public static Promise<int32, void> Eat(int32 n, int32 t)
	{
		return Promise<int32, void>.Create(.. new .(), new (v) =>
			{
				Thread.Sleep(t);
				Console.WriteLine("eted");
				return .Ok(n);
			}, executor);
	}

	public static Promise<int32, void> Lie(int32 n, int32 t)
	{
		return Promise<int32, void>.Create(.. new .(), new (v) =>
			{
				Thread.Sleep(t);
				Console.WriteLine("lied");
				return .Ok(n);
			}, executor);
	}
}