namespace Versprechen;

using System;
using System.Collections;
using System.Threading;

class LFQueue<T> where T : class
{
	private class QueueNode
	{
		public volatile QueueNode Next = null;
		public T Current = null;
	}

	private QueueNode Head = null;

	public void PushFront(T item)
	{
		QueueNode i = new .();
		i.Current = item;

		QueueNode head = Head;
		while (Interlocked.CompareExchange(ref Head, head, i) != head)
			head = Head;
		i.Next = head;
	}

	public T Pop()
	{
		QueueNode head = Head;

		while (head != null && Interlocked.CompareExchange(ref Head, head, head.Next) != head)
			head = Head;

		defer delete head;
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