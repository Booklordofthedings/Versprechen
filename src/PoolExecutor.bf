namespace Versprechen;
using Versprechen.Internal;

using System;
using System.Collections;
using System.Threading;

class PoolExecutor
{
	private bool shouldClose = false;
	private uint8 threadCount;
	private uint8 next = 0;
	private List<Thread> runners;
	private List<LFQueue<PromiseValue>> workItems;

	public this(uint8 threads = 4)
	{
		threadCount = threads;
		runners = new .(threadCount);
		workItems = new .(threadCount);

		for (var i < threadCount)
			workItems.Add(new .());

		for (var i < threadCount)
		{
			var r = new Thread(new () =>
				{
					ThreadFunction(i);
				});
			r.SetJoinOnDelete(true);
			r.AutoDelete = false;
			r.Start();
			runners.Add(r);
		}
	}

	public ~this()
	{
		shouldClose = true;
		DeleteContainerAndItems!(runners);
		DeleteContainerAndItems!(workItems);
	}

	private void ThreadFunction(uint8 id)
	{
		LFQueue<PromiseValue> target = workItems[id];

		while (!shouldClose)
		{
			var object = target.Pop();
			while (object != null)
			{
				ExecutePM(object);
				object = target.Pop();
			} //No more objects left for now

			if (object != null)
				ExecutePM(object);

			repeat
			{
				TrySteal();
				object = target.Pop();
			} while (object == null && !shouldClose);

			if (object != null)
				ExecutePM(object);
		}
	}

	private static void ExecutePM(PromiseValue v)
	{
		v.Resolver.Invoke();
		delete v.Dereference();
	}

	public virtual void Add(PromiseValue v)
	{
		v.Executor = this;
		var target = Interlocked.Increment(ref next);
		workItems[target % threadCount].PushFront(v);
	}

	[Inline]
	public virtual void TrySteal()
	{
		for (int i < threadCount)
		{
			var wi = workItems[i].Pop();
			if (wi != null)
			{
				ExecutePM(wi);
				return;
			}
		}
	}
}