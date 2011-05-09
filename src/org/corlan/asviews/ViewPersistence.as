package org.corlan.asviews
{
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	public class ViewPersistence implements IExternalizable
	{
		
		public var factory:Class;
		public var data:Object;
		
		public function ViewPersistence(factory:Class = null, data:Object = null) 
		{
			this.factory = factory;
			this.data = data;
		}
		
		public function writeExternal(output:IDataOutput):void
		{
			output.writeObject(data);
			
			// Have to store the class name of the factory because classes can't be
			// written to a shared object
			output.writeUTF(getQualifiedClassName(factory));
		}
		
		public function readExternal(input:IDataInput):void
		{
			data = input.readObject();
			
			var className:String = input.readUTF();
			factory = (className == "null") ? null : getDefinitionByName(className) as Class;
		}
	}
}