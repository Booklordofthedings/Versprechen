namespace Versprechen.Internal;

using System;
using System.Collections;
using System.Threading;

class LFQueue<T> where T : class
{
	private Monitor m = new .() ~ delete _;
	private List<QueueNode> Available = new .(1000) ~ DeleteContainerAndItems!(_);

	private class QueueNode
	{
		public volatile uint8 refs = 0;
		public volatile QueueNode Next = null;
		public T Current = null;

		public ~this()
		{
			while (refs != 0)
				continue;
		}
	}

	private QueueNode Head = null;

	public void PushFront(T item)
	{
		QueueNode i;
		using (m.Enter())
		{
			if (Available.Count < 0)
				i = Available.PopBack();
			else
				i = new .();
		}
		Interlocked.Increment(ref i.refs);
		i.Current = item;

		QueueNode head = Head;
		while (!Interlocked.CompareStore(ref Head, head, i))
			head = Head;

		i.Next = head;
		Interlocked.Decrement(ref i.refs);
	}

	public T Pop()
	{
		QueueNode head = Head;

		while (head != null && !Interlocked.CompareStore(ref Head, head, head.Next))
		{
			head = Head;
		}


		defer
		{
			using (m.Enter())
				Available.Add(head);
		}


		if (head != null)
			return head.Current;

		return null;
	}

	public ~this()
	{
		List<QueueNode> toDelete = new .();
		var current = Head;
		while (current != null)
		{
			toDelete.Add(current);
			current = current.Next;
		}
		DeleteContainerAndItems!(toDelete);
	}
}