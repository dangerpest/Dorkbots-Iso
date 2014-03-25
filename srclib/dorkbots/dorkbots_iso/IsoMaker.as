/*
TO DO

---
Create a map class that can be toggled on and off - clean up
it only needs heroCartPos
has its own createLevel, us only walkable level data	


---
Block trigers by putting the room numbers into an array.
this class double checks this array before swapping rooms.
For progression, locking and un-locking rooms.


---
Change roomData Array, make it use entities.
Don't destroy or null this array when putting room into stasis
Entity Stasis
Method for getting back the entity art when in stasis/after stasis.
from Entity factory
entities will need to preserve their health.
add attack button/command
enemie use same attack interface?
broadcast event when attack and attacking - entity
build UI including button, button is for touch screens and for mouse control


---
VIEW
Dependency injection
View is Abstracted, polymorphiable - allows swapping view technology (display list or Starling/Citrus, etc.)
Encapsulated by IsoMaker
injected by instantiator, as parameter

Entities polymorph animation and direction.
Give more flexibility via inheritance of entities.
Include attack and direction of attack.
developers can then customize via inheritance

node art class. Returns bitmap data instead of using movie clips. Movie clips are still used but instead turned into bitmaps.

first build interface for Entities, refactor view to them.


---
Attacking, health and death
Build state system for entities, Flee, Flock, Hunt, etc.
Entity class has list of entities
- Flee
- Allies
- Hunt

Entity
Create static strings for face directions and attacking, etc. match frame names, allow morphing. This allows for the sharing of frames, delaying the need to build specific animations. Good for prototyping or just for flexibility.
For attack, only need to add static string and frames, START HERE

---
room data trigger method - allows mapping of triggers via inheritance/polymorphing
use ex: triggers in a room all lead to the same room
uses conditionals to find and return the room to open
pass trigger number to find and return next room
use conditionals to find where to place the hero
pass the past room to find and return hero's place
Default method returns the same number as the last room, for the hero to stand
Default method returns the trigger number that was passed.


*/

package dorkbots.dorkbots_iso
{
	import com.csharks.juwalbose.IsoHelper;
	import com.senocular.utils.KeyObject;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	
	import dorkbots.dorkbots_broadcasters.BroadcastingObject;
	import dorkbots.dorkbots_broadcasters.IBroadcastedEvent;
	import dorkbots.dorkbots_iso.entity.Entity;
	import dorkbots.dorkbots_iso.entity.EntityFactory;
	import dorkbots.dorkbots_iso.entity.Hero;
	import dorkbots.dorkbots_iso.entity.IEnemy;
	import dorkbots.dorkbots_iso.entity.IEntity;
	import dorkbots.dorkbots_iso.entity.IEntityFactory;
	import dorkbots.dorkbots_iso.entity.IHero;
	import dorkbots.dorkbots_iso.room.IIsoRoomData;
	import dorkbots.dorkbots_iso.room.IIsoRoomsManager;
	import dorkbots.dorkbots_util.RemoveDisplayObjects;

	public class IsoMaker extends BroadcastingObject implements IIsoMaker
	{
		public static const ROOM_CHANGE:String = "room change";
		public static const PICKUP_COLLECTED:String = "pickup collected";
		public static const HERO_SHARING_NODE_WITH_ENEMY:String = "hero sharing node with enemy";
		
		//the canvas
		private var _canvas:Bitmap;
		private var rect:Rectangle;
		
		private var floor_bmp:BitmapData;
		private var floorBitmapMatrixTransOffset:Point;
		
		private var viewPortCornerPoint:Point = new Point();
		protected var _viewWidth:Number = 800;
		protected var _viewHeight:Number = 600
		
		protected var _borderOffsetY:Number = 20;
		protected var _borderOffsetX:Number = 320;
		 
		//Senocular KeyObject Class
		private var key:KeyObject;
		
		private var underKeyBoardControl:Boolean = false;
		
		private var roomsManager:IIsoRoomsManager;
		private var roomData:IIsoRoomData;
		private var entityFactory:IEntityFactory;
		
		private var container_mc:DisplayObjectContainer;
		
		private var triggerReset:Boolean = true;
		
		private var _hero:IHero;
		private var _enemyTargetNode:Point;
		private var _enemiesSeekHero:Boolean = true;
		
		public function IsoMaker(aContainer_mc:DisplayObjectContainer, aRoomsManager:IIsoRoomsManager, aEntityFactory:IEntityFactory = null)
		{
			container_mc = aContainer_mc;
			roomsManager = aRoomsManager;
			entityFactory = aEntityFactory;
			
			if (!entityFactory) entityFactory = new EntityFactory();
			
			if (container_mc.stage)
			{
				containerAddedToStage();
			}
			else
			{
				container_mc.addEventListener(Event.ADDED_TO_STAGE, containerAddedToStage);
			}
		}

		public final function set borderOffsetY(value:Number):void
		{
			_borderOffsetY = value;
		}

		public final function set borderOffsetX(value:Number):void
		{
			_borderOffsetX = value;
		}

		public final function set viewHeight(value:Number):void
		{
			_viewHeight = value;
		}

		public final function set viewWidth(value:Number):void
		{
			_viewWidth = value;
		}

		private function containerAddedToStage(event:Event = null):void
		{
			container_mc.removeEventListener(Event.ADDED_TO_STAGE, containerAddedToStage);
			key = new KeyObject(container_mc.stage);
			container_mc.addEventListener(MouseEvent.CLICK, handleClick);
		}
		
		override public function dispose():void
		{
			_canvas = null;
			key.deconstruct();
			roomsManager.dispose();
			roomData = null;
			container_mc.removeEventListener(MouseEvent.CLICK, handleClick);
			container_mc = null;
			entityFactory.dispose();
			entityFactory = null;
			
			super.dispose();
		}
		
		/********************************************************************************
		 * GETTERS AND SETTERS
		 ********************************************************************************/
		public final function get enemiesSeekHero():Boolean
		{
			return _enemiesSeekHero;
		}
		
		public final function set enemiesSeekHero(value:Boolean):void
		{
			_enemiesSeekHero = value;
		}
		
		public final function get enemyTargetNode():Point
		{
			return _enemyTargetNode;
		}
		
		public final function set enemyTargetNode(value:Point):void
		{
			_enemyTargetNode = value;
		}
		
		public final function get hero():IHero
		{
			return _hero;
		}
		
		public final function get canvas():Bitmap
		{
			return _canvas;
		}

		public final function start():void
		{
			createRoom();
		}
		
		
		/********************************************************************************
		 * CREATING A ROOM
		 ********************************************************************************/
		private function createRoom():void
		{			
			roomData = roomsManager.getRoom(roomsManager.roomCurrentNum);
			roomData.init();
			
			if (!_hero)
			{
				// only create Hero once
				_hero = entityFactory.createHero();
			}
			
			_hero.init(roomData.speed, roomData.heroHalfSize, 1);
			_hero.wake(roomData.hero, roomData);
			
			_canvas = new Bitmap( new BitmapData( _viewWidth, _viewHeight ) );
			rect = _canvas.bitmapData.rect;
			RemoveDisplayObjects.removeAllDisplayObjects(container_mc);
			container_mc.addChild(_canvas);
			
			_hero.facingCurrent = "";
			
			
			
			
			/********************************************************************************
			 * TO DO
			 * postion method for entities
			********************************************************************************/
			if (!roomsManager.roomHasChanged)
			{
				_hero.facingNext = _hero.facingCurrent = roomData.heroFacing;
			}
			_hero.entity_mc.clip.gotoAndStop(_hero.facingNext);
			
			
			// Look for hero
			var buildHero:Boolean = false;
			var tileType:uint;
			var adjustedX:Number;
			var adjustedY:Number;
			var enemy:IEnemy;
			var i:uint;
			// label for the first loop, used for break
			toploop: 
			for (i = 0; i < roomData.roomNodeGridHeight; i++)
			{
				for (var j:uint = 0; j < roomData.roomNodeGridWidth; j++)
				{		
					tileType = roomData.roomEntities[i][j];
					if (!roomsManager.roomHasChanged)
					{
						// first room
						if (tileType == 1)
						{
							buildHero = true;
						}
					}
					else
					{
						// rooms have swapped, place hero on trigger for previous room
						if (roomData.roomTriggers[i][j] == roomsManager.roomLastNum + 1)
						{
							buildHero = true;
						}	
					}
					
					// found enemy, create enemy only if room is not in stasis, this means room is a new and enemies have yet to be created.
					if (tileType > 1 && !roomData.stasis)
					{
						enemy = entityFactory.createEnemy(tileType);
						roomData.enemies.push( enemy.init( roomData.speed, roomData.enemyHalfSize, tileType ) );
						placeEntity(enemy, j, i);
					}
					
					
					if (buildHero)
					{
						// found hero, makes sure hero is positioned in the center of the screen
						placeEntity(_hero, j, i);
						
						postionViewPortCornerPoint();
						
						var pos:Point = _hero.cartPos.clone();
						pos.x += viewPortCornerPoint.x;
						pos.y += viewPortCornerPoint.y;
						pos = IsoHelper.twoDToIso(pos);
						_hero.entity_mc.x = _borderOffsetX + pos.x;
						_hero.entity_mc.y = _borderOffsetY + pos.y;
						
						buildHero = false;
						
						//break toploop;
					}				
				}
			}
			
			roomData.wake();
			entityMoved(_hero);
			
			// wake any enemies from stasis, if room is in stasis. Also wakes new enemies.
			for (i = 0; i < roomData.enemies.length; i++)
			{
				enemy = roomData.enemies[i];
				enemy.addEventListener( Entity.PATH_ARRIVED_NEXT_NODE, enemyArrivedAtNextPathNode);
				enemy.wake( roomData.createEnemy(tileType), roomData );
				placeEntity(enemy, enemy.node.x, enemy.node.y);
				//roomData.entitiesGrid[enemy.node.y][enemy.node.x].push(enemy);
				entityMoved(enemy)
			}
			
			updateEnemiesWalkable();
			if (_enemiesSeekHero) _enemyTargetNode = _hero.node;
			if (_enemyTargetNode)
			{
				for (i = 0; i < roomData.enemies.length; i++)
				{
					roomData.enemies[i].findPathToNode(_enemyTargetNode);
				}
			}
			
			 drawFloor();
			drawToCanvas();
		}
		
		private function postionViewPortCornerPoint():void
		{
			viewPortCornerPoint.x = viewPortCornerPoint.y = 0;
			viewPortCornerPoint.x -= (_hero.cartPos.x - (_viewWidth / 2)) + _hero.entity_mc.width;
			viewPortCornerPoint.y -= _hero.cartPos.y - (_viewHeight / 2);
		}
		
		private function placeEntity(entity:IEntity, x:uint, y:uint):void
		{			
			//find the middle of the node
			entity.cartPos.x = x * roomData.nodeWidth + (roomData.nodeWidth / 2);
			entity.cartPos.y = y * roomData.nodeWidth + (roomData.nodeWidth / 2);
			
			entity.node.x = x;
			entity.node.y = y;
		}
		
		private function drawFloor():void
		{			
			var tileType:uint;
			var mat:Matrix = new Matrix();
			var pos:Point = new Point();
			roomData.roomTileArtWithHeight = new Array();
			
			// make sure bitmap data is big enough to fit all tile art
			floor_bmp = new BitmapData( ( roomData.roomNodeGridWidth * roomData.nodeWidth ) * 2, ( roomData.roomNodeGridHeight * roomData.nodeWidth ) * 2);
			
			floorBitmapMatrixTransOffset = new Point(( roomData.roomNodeGridWidth * roomData.nodeWidth ) / 2, ( roomData.roomNodeGridHeight * roomData.nodeWidth ) / 2);
			for (var i:uint = 0; i < roomData.roomNodeGridHeight; i++)
			{
				roomData.roomTileArtWithHeight[i] = new Array();
				for (var j:uint = 0; j < roomData.roomNodeGridWidth; j++)
				{
					tileType = roomData.roomTileArt[i][j];
					
					if (roomData.tileArtWithHeight.indexOf(tileType) < 0)
					{
						// tile art does not have height so draw it to the floor						
						// draw floor tile
						pos.x = j * roomData.nodeWidth;
						pos.y = i * roomData.nodeWidth;
						
						pos = IsoHelper.twoDToIso(pos);
						// push the tiles to the right and down, to make sure all tiles are drawn
						mat.tx = _borderOffsetX + pos.x;
						mat.ty = _borderOffsetY + pos.y;
						mat.translate(floorBitmapMatrixTransOffset.x, floorBitmapMatrixTransOffset.y);
						
						roomData.tileArt.gotoAndStop( tileType + 1 );
						floor_bmp.draw( roomData.tileArt, mat );
						
						// 0 = tile art with no height.
						roomData.roomTileArtWithHeight[i][j] = 0;
					}
					else
					{
						// tile art does have height so add it to the tile art height arrays
						roomData.roomTileArtWithHeight[i][j] = tileType + 1;
					}
				}
			}

			floor_bmp.unlock();
		}
		
		
		/********************************************************************************
		 * DRAWING TO CANVAS
		 ********************************************************************************/
		//sort depth & draw to canvas
		private function drawToCanvas():void
		{
			_canvas.bitmapData.lock();
			_canvas.bitmapData.fillRect(rect, 0xffffff);
			
			var tileType:uint;
			var mat:Matrix = new Matrix();
			var pos:Point = new Point();
			var enemy:IEnemy;
			var entity:IEntity;
			var enemiesAddedToNode:uint = 0;
			var addHero:Boolean = false;
			var entitiesToAddToNode:Array = new Array();
			var k:int = 0;
			
			pos.x = viewPortCornerPoint.x;
			pos.y = viewPortCornerPoint.y;
			
			pos = IsoHelper.twoDToIso(pos);
			mat.tx = pos.x;
			mat.ty = pos.y;
			
			// draw the floor
			// move the floor bitmap data back over so it matches the rest of the room
			mat.translate(-floorBitmapMatrixTransOffset.x, -floorBitmapMatrixTransOffset.y);
			_canvas.bitmapData.draw( floor_bmp, mat );
			
			for (var i:uint = 0; i < roomData.roomNodeGridHeight; i++)
			{
				for (var j:uint = 0; j < roomData.roomNodeGridWidth; j++)
				{
					entitiesToAddToNode.length = 0;
					//addHero = false;
					
					pos.x = j * roomData.nodeWidth + viewPortCornerPoint.x;
					pos.y = i * roomData.nodeWidth + viewPortCornerPoint.y;
					
					pos = IsoHelper.twoDToIso(pos);
					mat.tx = _borderOffsetX + pos.x;
					mat.ty = _borderOffsetY + pos.y;
					
					// TO DO
					// node art class. Returns bitmap data instead of using movie clips. Movie clips are still used but instead turned into bitmaps.
					// tile art with height
					tileType = roomData.roomTileArtWithHeight[i][j];
					if (tileType > 0)
					{						
						roomData.tileArt.gotoAndStop( tileType );
						_canvas.bitmapData.draw( roomData.tileArt, mat);
					}					
					
					// pick ups
					tileType = roomData.roomPickups[i][j];
					if(tileType > 0)
					{
						roomData.tilePickup.gotoAndStop(tileType);
						_canvas.bitmapData.draw(roomData.tilePickup, mat);
					}
					
					enemiesAddedToNode = 0;
					
					for (k = 0; k < roomData.entitiesGrid[i][j].length; k++) 
					{
						entity = roomData.entitiesGrid[i][j][k];
						if (entity is Hero)
						{
							mat.tx = _hero.entity_mc.x;
							mat.ty = _hero.entity_mc.y;
							entitiesToAddToNode.push( {matrixTY: mat.ty, matrix: mat.clone(), entity: entity} );
						}
						else
						{
							pos.x = entity.cartPos.x + viewPortCornerPoint.x;
							pos.y = entity.cartPos.y + viewPortCornerPoint.y;
							pos = IsoHelper.twoDToIso(pos);
							mat.tx = _borderOffsetX + pos.x;
							mat.ty = _borderOffsetY + pos.y - (enemiesAddedToNode * 2);
							
							entitiesToAddToNode.push( {matrixTY: mat.ty, matrix: mat.clone(), entity: entity} );
							
							enemiesAddedToNode++;
						}
						
					}
					
					// add entities bassed on their matrix.ty, so that entities with a higher ty will be drawn in front
					if (entitiesToAddToNode.length > 0)
					{
						entitiesToAddToNode.sortOn("matrixTY", Array.NUMERIC);
						for (k = 0; k < entitiesToAddToNode.length; k++) 
						{
							_canvas.bitmapData.draw( IEntity(entitiesToAddToNode[k].entity).entity_mc, entitiesToAddToNode[k].matrix);
						}
					}
				}
			}
			
			_canvas.bitmapData.unlock();
		}
		
		
		/********************************************************************************
		 * LOOP
		 ********************************************************************************/
		//the game loop
		public final function loop():void
		{
			var movement:Boolean = false;
			
			// Move and update hero
			_hero.loop();
			
			keyBoardControl();
			
			_hero.move();
			
			if (_hero.moved)
			{				
				if (heroMoved())
				{
					movement = true;
					
					viewPortCornerPoint.x -=  _hero.movedAmountPoint.x;
					viewPortCornerPoint.y -=  _hero.movedAmountPoint.y;
					entityMoved(_hero);
				}
			}
			
			if (_enemiesSeekHero) _enemyTargetNode = hero.node;
			
			// move enemies
			updateEnemiesWalkable();
			
			var i:int;
			var enemy:IEnemy;
			
			// update enemies
			for (i = 0; i < roomData.enemies.length; i++) 
			{
				enemy = roomData.enemies[i];
				roomData.enemiesWalkable[enemy.node.y][enemy.node.x] = 0;
				enemy.loop();
				enemy.move();
				if (enemy.destroyed)
				{
					// dispose of enemy
					movement = true;
					disposeOfEnemy(enemy);
				}
				else
				{
					roomData.enemiesWalkable[enemy.node.y][enemy.node.x] = enemy.type;
					
					// if enemy has stopped hunting, set a new path for the hero
					if (!enemy.finalDestination && !enemy.node.equals(_enemyTargetNode) )
					{
						if (_enemyTargetNode) enemy.findPathToNode(_enemyTargetNode);
					}
					
					if (enemy.moved)
					{
						//trace("enemy move");
						movement = true;
						entityMoved(enemy);
					}
					
					if (enemy.node.equals(_hero.node))
					{
						broadcastEvent( HERO_SHARING_NODE_WITH_ENEMY, {enemy: enemy} );
						if(enemy.attackReady())
						{
							// TO DO
							// attack hero
						}
					}
				}
			}
			
			if (movement)
			{
				drawToCanvas();
			}
		}
		
		private function swapRoom(roomNumber:uint):void
		{
			putEnemiesInStasis();
			
			roomsManager.putRoomInStasis(roomData);
			roomsManager.roomCurrentNum = roomNumber;
			createRoom();
			
			broadcastEvent(ROOM_CHANGE, {roomNumber: roomNumber});
			
			triggerReset = false;
		}
		
		
		/********************************************************************************
		 * ENTITY STUFF
		 ********************************************************************************/
		// remove entity from previous node, add to new
		private function entityMoved(entity:IEntity):void
		{
			removeEntityFromGrid(entity);
			roomData.entitiesGrid[entity.node.y][entity.node.x].push(entity);
		}
		
		private function removeEntityFromGrid(entity:IEntity):void
		{
			var array:Array = roomData.entitiesGrid[entity.nodePrevious.y][entity.nodePrevious.x];
			var index:int = array.indexOf(entity);
			if (index > -1) array.splice(index, 1);
			
			array = roomData.entitiesGrid[entity.node.y][entity.node.x];
			index = array.indexOf(entity);
			if (index > -1) array.splice(index, 1);
		}
		
		
		/********************************************************************************
		 * ENEMIES STUFF
		 ********************************************************************************/
		private function enemyArrivedAtNextPathNode(event:IBroadcastedEvent):void
		{
			var enemy:IEnemy = IEnemy(event.owner());
			if (enemy.finalDestination)
			{
				if(!enemy.finalDestination.equals(_enemyTargetNode)) 
				{
					enemy.findPathToNode(_enemyTargetNode);
				}
			}
			else
			{
				if ( !enemy.node.equals(_enemyTargetNode) ) enemy.findPathToNode(_enemyTargetNode);
			}
		}
		
		public final function enemyDestroy(enemy:IEnemy):void
		{
			// the loop performs full destroy of enemy
			enemy.destroyed = true;
		}
		
		private function disposeOfEnemy(enemy:IEnemy):void
		{
			removeEntityFromGrid(enemy);
			roomData.enemies.splice( roomData.enemies.indexOf( enemy ) , 1 );
			roomData.roomEntities[enemy.node.y][enemy.node.x] = 0;
			enemy.dispose();
		}
		
		private function putEnemiesInStasis():void
		{
			var i:uint;
			var enemy:IEnemy
			for (i = 0; i < roomData.enemies.length; i++) 
			{
				enemy = roomData.enemies[i];
				enemy.removeEventListener( Entity.PATH_ARRIVED_NEXT_NODE, enemyArrivedAtNextPathNode);
				roomData.roomEntities[enemy.node.y][enemy.node.x] = enemy.type;
				enemy.putInStasis();
			}
		}
		
		// add enemy node position to enemies walkable, so enemies don't occupy the same node.
		private function updateEnemiesWalkable():void
		{
			var newWalkable:Array = roomData.enemiesWalkable;
			
			var i:int;
			var enemy:IEnemy;
			
			for (i = 0; i < roomData.roomNodeGridHeight; i++)
			{
				newWalkable[i] = roomData.roomWalkable[i].slice();
			}
			
			for (i = 0; i < roomData.enemies.length; i++) 
			{
				enemy = roomData.enemies[i];
				newWalkable[enemy.node.y][enemy.node.x] = 1;
			}
		}
		
		
		/********************************************************************************
		 * HERO
		 ********************************************************************************/
		/**
		 * heroMoved
		 * 
		 * returns Boolean - false if trigger found.
		 */
		private function heroMoved():Boolean
		{
			// Map
			/*heroPointer.x = heroCartPos.x;
			heroPointer.y = heroCartPos.y;*/
			
			var newPos:Point = IsoHelper.twoDToIso(_hero.cartPos);
			
			var pickupType:uint = isPickup( _hero.node );
			if( pickupType > 0 )
			{
				pickupItem( _hero.node );
				broadcastEvent( PICKUP_COLLECTED, {type:pickupType});
			}	
			
			var triggerNode:uint = roomData.roomTriggers[ _hero.node.y ][ _hero.node.x ];
			if (triggerNode > 0)
			{
				// FOUND ROOM SWAP TRIGGER
				// now that it's been established that the current hero node (trigerNode) is a trigger, we decrease it so that it is inline with the room numbering. Arrays start at 0.
				triggerNode--;
				if (triggerNode != roomsManager.roomCurrentNum)
				{
					if (triggerReset)
					{
						swapRoom(triggerNode);
						
						return false;
					}
				}
			}
			else
			{
				triggerReset = true;
			}
			
			return true;
		}
		
		/**
		 * Pickups
		 */
		private function isPickup(tilePt:Point):uint
		{
			return roomData.roomPickups[ tilePt.y ][ tilePt.x ];
		}
		
		private function pickupItem(tilePt:Point):void
		{
			roomData.roomPickups[ tilePt.y ][ tilePt.x ] = 0;
		}
		
		/**
		 * Room triggers
		 */
		private function isTrigger(tilePt:Point):Boolean
		{
			return( roomData.roomTriggers[ tilePt.y ][ tilePt.x ] > 0 );
		}

		/**
		 * Keyboard Control
		 */
		private function keyBoardControl():void
		{
			var keyBoardControl:Boolean = false;
			var pathFinding:Boolean = false;
			if (_hero.path.length > 0) pathFinding = true;
			
			if (key.isDown( Keyboard.UP ))
			{
				_hero.dY = -1;
				keyBoardControl = true;
			}
			else if (key.isDown( Keyboard.DOWN ))
			{
				_hero.dY = 1;
				keyBoardControl = true;
			}
			else
			{
				if (!pathFinding) _hero.dY = 0;
			}
			
			if (key.isDown( Keyboard.RIGHT ))
			{
				_hero.dX = 1;
				if (_hero.dY == 0)
				{
					_hero.facingNext = "east";
				}
				else if (_hero.dY == 1)
				{
					_hero.facingNext = "southeast";
					_hero.dX = _hero.dY = 0.5;
				}
				else
				{
					_hero.facingNext = "northeast";
					_hero.dX = 0.5;
					_hero.dY =- 0.5;
				}
				keyBoardControl = true;
			}
			else if (key.isDown( Keyboard.LEFT ))
			{
				_hero.dX = -1;
				if (_hero.dY == 0)
				{
					_hero.facingNext = "west";
				}
				else if (_hero.dY == 1)
				{
					_hero.facingNext = "southwest";
					_hero.dY = 0.5;
					_hero.dX =- 0.5;
				}
				else
				{
					_hero.facingNext = "northwest";
					_hero.dX = _hero.dY =- 0.5;
				}
				keyBoardControl = true;
			}
			else
			{
				if (!pathFinding) 
				{
					_hero.dX = 0;
					if (_hero.dY == 0)
					{
						//facing="west";
					}
					else if (_hero.dY == 1)
					{
						_hero.facingNext = "south";
					}
					else
					{
						_hero.facingNext = "north";
					}
				}
			}
			
			if (keyBoardControl)
			{
				//key board control active. Stop pathfinding
				_hero.path.length = 0;
				underKeyBoardControl = true;
			}
		}
		
		/**
		 * Click Control
		 */
		private function handleClick(e:MouseEvent):void
		{
			var clickPt:Point = new Point();
			
			clickPt.x = e.stageX - _borderOffsetX;
			clickPt.y = e.stageY - _borderOffsetY;
			//trace("{IsoMaker} handleMouseClick -> clickPt = " + clickPt);
			
			clickPt = IsoHelper.isoTo2D(clickPt);
			//trace("{IsoMaker} handleMouseClick -> isoTo2D clickPt = " + clickPt);
			
			clickPt.x -= roomData.nodeWidth / 2 + viewPortCornerPoint.x;
			clickPt.y += roomData.nodeWidth / 2 - viewPortCornerPoint.y;
			
			//trace("{IsoMaker} handleMouseClick -> half node width clickPt = " + clickPt);
			
			clickPt = IsoHelper.getNodeCoordinates( clickPt, roomData.nodeWidth );
			//trace("{IsoMaker} handleMouseClick -> clickPt in Node Coordinates = " + clickPt);
			if(clickPt.x < 0 || clickPt.y < 0 || clickPt.x > roomData.roomWalkable.length - 1 || clickPt.x > roomData.roomWalkable[0].length - 1)
			{
				//trace("{IsoMaker} handleMouseClick -> clicked outside of the room");
				return;
			}
			if (!hero.isWalkable(roomData.roomWalkable[clickPt.y][clickPt.x]))
			{
				//trace("{IsoMaker} handleMouseClick -> clicked on a non walkable node");
				return;
			}
			
			// if hero was under keyboard control, then first place it in the center of its current node. otherwise the visual position is broken
			if (underKeyBoardControl)
			{
				_hero.dX = _hero.dY = 0;
				_hero.putEntityInMiddleOfNode();
				_hero.move();
				postionViewPortCornerPoint();
				
				underKeyBoardControl = false;
			}
			
			//trace("{IsoMaker} handleMouseClick -> hero Node = " + hero.node + ", clickPt = " + clickPt);
			_hero.findPathToNode(clickPt, false);
			
			// TO DO
			// display path in Map
		}
	}
}