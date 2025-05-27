namespace Versprechen;
using Versprechen.Internal;

using System;

/*
	Promise has almost no actual data, its only really a interface to interact with PromiseValue
*/
class Promise<T, E>
{

	///Create a new promise and schedule it to be executed
	public static void Create(Promise<T, E> p, delegate Result<T, E>(PromiseValue v) func, PoolExecutor executor)
	{
		PromiseValue v = new .();
		v.[Friend]Resolver = new () =>
			{
				v.Resolve(func.Invoke(v));
				delete func;
			};
		p.mValue = v;

		if (executor != null)
			executor.Add(v);
		else
		{
			v.[Friend]Resolver.Invoke();
			delete v.Dereference();
		}
	}

	private PromiseValue mValue ~ delete _.Dereference();

	///Wait until the promise has been resolved
	public Result<T, E> Await()
	{
		mValue.Await();
		return mValue.[Friend]Result.Get<Result<T, E>>();
	}

	public void OnCleanup(delegate void(Result<T, E>) func)
	{
		mValue.OnDelete = new () =>
			{
				Console.WriteLine(mValue.Result.IsObject);
				func.Invoke(mValue.Result.Get<Result<T, E>>());
				delete func;
			};
	}

	public void OnErr(delegate void(E) func)
	{
		if (mValue.References == 1)
		{
			if (mValue.Result.Get<Result<T, E>>() case .Err(let e))
				func.Invoke(e);

			delete func;
		}
		else
		{
			mValue.OnErr.PushFront(new (v) =>
				{
					if (v.Get<Result<T, E>>() case .Err(let e))
						func.Invoke(e);

					delete func;
				});
		}
	}

	public void OnOk(delegate void(T) func)
	{
		if (mValue.References == 1)
		{
			if (mValue.Result.Get<Result<T, E>>() case .Ok(let val))
				func.Invoke(val);

			delete func;
		}
		else
		{
			mValue.OnOk.PushFront(new (v) =>
				{
					if (v.Get<Result<T, E>>() case .Ok(let val))
						func.Invoke(val);

					delete func;
				});
		}
	}

	public void Then(delegate void(Result<T, E>) func)
	{
		if (mValue.References == 1)
		{
			func.Invoke(mValue.Result.Get<Result<T, E>>());
			delete func;
		}
		else
		{
			mValue.OnResolve.PushFront(new (v) =>
				{
					func.Invoke(v.Get<Result<T, E>>());
					delete func;
				});
		}
	}

	///Wether the promise has been resolved, doesnt block
	public bool Resolved
	{
		public get => mValue.References != 2;
	}

}