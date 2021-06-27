#nullable enable
using Godot;
using System;
using System.Linq;
using System.Reflection;
using System.Threading.Tasks;
using Godot.Collections;
using Object = Godot.Object;

namespace WAT 
{
	
	public class Test : Node
	{
		[AttributeUsage(AttributeTargets.Method)] protected class TestAttribute: Attribute { }
		[Signal] public delegate void executed();
		[Signal] public delegate void Described();

		protected const string YIELD = "finished";
		private const bool TEST = true;
		private const int Recorder = 0; // Apparently we require the C# Version
		private Godot.Collections.Array _methods;
		private Object _case;
		private static readonly GDScript Any = GD.Load<GDScript>("res://addons/WAT/test/any.gd");
		private readonly Object _watcher = (Object) GD.Load<GDScript>("res://addons/WAT/test/watcher.gd").New();
		private readonly Object _registry = (Object) GD.Load<GDScript>("res://addons/WAT/double/registry.gd").New();
		protected readonly Node Direct = (Node) GD.Load<GDScript>("res://addons/WAT/double/factory.gd").New();
		protected readonly Timer Yielder = (Timer) GD.Load<GDScript>("res://addons/WAT/test/yielder.gd").New();
		protected Assertions Assert = new Assertions();

		public Test()
		{
			
		}
		public Test setup(Dictionary<string, object> metadata)
		{
			Console.WriteLine(metadata["methods"].GetType());
			_methods = (Godot.Collections.Array) metadata["methods"];
			_case = (Object) GD.Load<GDScript>("res://addons/WAT/test/case.gd").New(this, metadata);
			return this;
		}

		// ReSharper disable once InconsistentNaming
		public async void run()
		{
			int cursor = 0;
			await Execute("Start")!;
			while (cursor < _methods.Count)
			{
				string currentMethod = (string) _methods[cursor];
				_case.Call("add_method", currentMethod);
				await Execute("Pre")!;
				await Execute(currentMethod)!;
				await Execute("Post")!;
				cursor++;
			}
			await Execute("End")!;
			EmitSignal(nameof(executed));
		}

		private async Task? Execute(string method)
		{
			if (GetType().GetMethod(method)?.Invoke(this, null) is Task task)
			{
				await task;
			}
		}

		protected void Describe(string description) {EmitSignal(nameof(Described), description);}
		private string title() { return Title(); }
		public virtual string Title() { return GetType().Name; }

		// public virtual async Task? Start() { await Task.Run(() => { });}
		// public virtual async Task? Pre() { await Task.Run(() => { }); }
		// public virtual async Task? Post() { }
		// protected virtual async Task? End() {}
		protected Timer UntilTimeout(double time) { return (Timer) Yielder.Call("until_timeout", time); }

		protected Timer UntilSignal(Godot.Object emitter, string signal, double time)
		{
			//watcher.Call("watch", emitter, signal);
			return (Timer) Yielder.Call("until_signal", time, emitter, signal);
		}
		public override void _Ready()
		{
			Direct.Set("registry", _registry);
			Assert.Connect(nameof(Assertions.asserted), _case, "_on_asserted");
			Connect(nameof(Described), _case, "_on_test_method_described");
			AddChild(Direct);
			AddChild(Yielder);
		}

		public Dictionary get_results()
		{
			_case.Call("calculate"); // #")
			Dictionary results = (Dictionary) _case.Call("to_dictionary");
			_case.Free();
			return results;
		}
		// protected Timer UntilSignal(Godot.Object emitter, string signal, double time)
		// {
		// 	watcher.Call("watch", emitter, signal);
		// 	return (Timer) yielder.Call("until_signal", time, emitter, signal);
		// }
		//
		// protected void Watch(Godot.Object emitter, string signal) { watcher.Call("watch", emitter, signal); }
		// protected void UnWatch(Godot.Object emitter, string signal) { watcher.Call("unwatch", emitter, signal); }


		private Array<string> GetTestMethods()
		{
			return new Array<string>(GetType().GetMethods()
				.Where(m => m.IsDefined(typeof(TestAttribute)))
				.Select(info => info.Name).ToList());
		}
	}
}
