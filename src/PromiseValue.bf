namespace Versprechen;

using System;
using System.Threading;

/*
	This entire class should be threadsafe due to how its intended to be accessed.
	Resolver -> Written once and only accessed after the write
	Result -> Written once and gated by References
	References -> Can be read normally, but only written to using deref, which is threadsafe
	OnErr -> Lockfree container
	OnOk -> Lockfree container
	OnResolve -> Lockfree container
*/
class PromiseValue
{
	public delegate void() Resolver ~ delete _;

	//This should always be set by the resolver, unless we fatal error at which point there are larger problems than an unset field
	public Variant Result ~ _.Dispose(); //Dispose needs to be called on any variant larger than 64bits


	/* References:
		This variable tracks which side of the promise still cares about its result.
		When the value is 0 this object should be deleted.
		If the value is 1 its possible to infer things based on the side that we are on.
		1 + Resolver: The promise object has already been deleted. We just need to run cleanup and then delete ourselves.
		1 + Promise: The Function is done executing and we can get the value
	*/
	public uint8 References = 2;

	/* Responses:
		Launches some automated responses, when the promise resolves.
		Delete will only occur when deref is called and sets references to 0.
		The others will be called by the resolver, after its done.
		If the promise has already been resolved adding a response will just make it execute immediately
		Execution Order: OnResolve						......->OnDelete
							|->OnErr
							|->OnOk
		!DO NOT DEPEND ON THE EXECUTION ORDER BEING A CERTAIN WAY AROUND! (Excluding the OnDelete being the last)
	*/
	public LFQueue<delegate void(Variant)> OnErr = new .() ~ delete _;
	public LFQueue<delegate void(Variant)> OnOk = new .() ~ delete _;
	public LFQueue<delegate void(Variant)> OnResolve = new .() ~ delete _;
	public delegate void() OnDelete  = null ~ delete _; //This will surely be only set once and then only be read on a delete
	//If this is the case it will be threadsafe

	public PoolExecutor Executor = null;

	///Effectivly just wraps the variant create call
	public void Resolve<T, E>(Result<T, E> res)
	{
		Result = Variant.Create<Result<T, E>>(res);

		var func = OnResolve.Pop();
		while (func != null)
		{
			func.Invoke(Result);
			delete func;
			func = OnResolve.Pop();
		}

		if (res case .Err)
		{
			func = OnErr.Pop();
			while (func != null)
			{
				func.Invoke(Result);
				delete func;
				func = OnErr.Pop();
			}
		}
		else
		{
			func = OnOk.Pop();
			while (func != null)
			{
				func.Invoke(Result);
				delete func;
				func = OnOk.Pop();
			}
		}
	}

	///!CALL DELETE ON THE RETURN VALUE OF THIS!
	public PromiseValue Dereference()
	{
		var val = Interlocked.Sub(ref References, 1);

		if (val == 0)
		{
			if (OnDelete != null)
				OnDelete.Invoke();
			return this;
		}
		return null;
	}

	public void Await()
	{
		if (References != 1)
			Thread.SpinWait(10);

		while (References != 1)
		{
			if (Executor != null)
				Executor.TrySteal();
		}
	}
}