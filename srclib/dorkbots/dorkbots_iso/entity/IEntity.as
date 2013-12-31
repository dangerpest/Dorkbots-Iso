package dorkbots.dorkbots_iso.entity
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import dorkbots.dorkbots_broadcasters.IBroadcastingObject;
	import dorkbots.dorkbots_iso.room.IIsoRoomData;

	public interface IEntity extends IBroadcastingObject
	{
		function get speed():Number;
		function set speed(value:Number):void;
		function putInStasis():void;
		function init(aSpeed:Number, aHalfSize:Number, aType:uint):IEntity
		function wake(a_mc:MovieClip, aRoomData:IIsoRoomData):IEntity
		function get destroyed():Boolean;
		function set destroyed(value:Boolean):void;
		function get type():uint;
		function get finalDestination():Point;
		function get health():Number;
		function set health(value:Number):void;
		function get healthMax():uint;
		function set healthMax(value:uint):void;
		function get dY():Number;
		function set dY(value:Number):void;
		function get dX():Number;
		function set dX(value:Number):void;
		function get path():Array;
		function get facingCurrent():String;
		function set facingCurrent(value:String):void;
		function get facingNext():String;
		function set facingNext(value:String):void;
		function get entity_mc():MovieClip;
		function get cartPos():Point;
		function set cartPos(value:Point):void;
		function get node():Point;
		function set node(value:Point):void;
		function get nodePrevious():Point;
		function get moved():Boolean;
		function loop():void;
		function move():void;
		function get movedAmountPoint():Point;
		function findPathToNode(nodePoint:Point, updateDestination:Boolean = true):void;
		function putEntityInMiddleOfNode():void;
		function isWalkable(num:uint):Boolean;
	}
}