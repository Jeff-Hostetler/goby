require 'goby'

RSpec.describe Entity do

  context "constructor" do
    it "has the correct default parameters" do
      entity = Entity.new
      expect(entity.name).to eq "Entity"
      expect(entity.max_hp).to eq 1
      expect(entity.hp).to eq 1
      expect(entity.attack). to eq 1
      expect(entity.defense).to eq 1
      expect(entity.agility).to eq 1
      expect(entity.inventory).to eq Array.new
      expect(entity.gold).to eq 0
      expect(entity.battle_commands).to eq Array.new
      expect(entity.outfit).to eq Hash.new
    end

    it "correctly assigns custom parameters" do
      hero = Entity.new(name: "Hero",
                        max_hp: 50,
                        hp: 35,
                        attack: 12,
                        defense: 4,
                        agility: 9,
                        inventory: [Couple.new(Item.new, 1)],
                        gold: 10,
                        outfit: { weapon: Weapon.new(
                                    attack: Attack.new,
                                    stat_change: {attack: 3, defense: 1, agility: 4}
                                  ),
                                  helmet: Helmet.new(
                                      stat_change: {attack: 1, defense: 5}
                                  ) },
                        battle_commands: [
                          Attack.new(name: "Punch"),
                          Attack.new(name: "Kick")
                        ])
      expect(hero.name).to eq "Hero"
      expect(hero.max_hp).to eq 50
      expect(hero.hp).to eq 35
      # Attack & defense increase due to the equipped items.
      expect(hero.attack).to eq 16
      expect(hero.defense).to eq 10
      expect(hero.agility).to eq 13
      expect(hero.inventory).to eq [Couple.new(Item.new, 1)]
      expect(hero.gold).to eq 10
      expect(hero.outfit[:weapon]).to eq Weapon.new
      expect(hero.outfit[:helmet]).to eq Helmet.new
      # Attack.new is present due to the equipped weapon.
      expect(hero.battle_commands).to eq [
        Attack.new,
        Attack.new(name: "Kick"),
        Attack.new(name: "Punch")
      ]
    end

    it "assigns default keyword arguments as appropriate" do
      entity = Entity.new(max_hp: 7,
                        defense: 9,
                        gold: 3)
      expect(entity.name).to eq "Entity"
      expect(entity.max_hp).to eq 7
      expect(entity.hp).to eq 7
      expect(entity.attack).to eq 1
      expect(entity.defense).to eq 9
      expect(entity.agility).to eq 1
      expect(entity.inventory).to eq []
      expect(entity.gold).to eq 3
      expect(entity.battle_commands).to eq []
    end
  end

  context "add battle command" do
    it "properly adds the command in a trivial case" do
      entity = Entity.new
      entity.add_battle_command(BattleCommand.new)
      expect(entity.battle_commands.length).to eq 1
      expect(entity.battle_commands).to eq [BattleCommand.new]
    end

    it "maintains the sorted invariant for a more complex case" do
      entity = Entity.new
      entity.add_battle_command(BattleCommand.new(name: "Kick"))
      entity.add_battle_command(BattleCommand.new(name: "Chop"))
      entity.add_battle_command(BattleCommand.new(name: "Grab"))
      expect(entity.battle_commands.length).to eq 3
      expect(entity.battle_commands).to eq [
        BattleCommand.new(name: "Chop"),
        BattleCommand.new(name: "Grab"),
        BattleCommand.new(name: "Kick")]
    end
  end

  context "add gold" do
    it "properly adds the appropriate amount of gold" do
      entity = Entity.new
      entity.add_gold(30)
      expect(entity.gold).to eq 30
    end

    it "prevents gold < 0" do
      entity = Entity.new
      entity.add_gold(-30)
      expect(entity.gold).to be_zero
    end
  end

  context "add item" do
    it "properly adds an item in a trivial case" do
      entity = Entity.new
      entity.add_item(Item.new)
      expect(entity.inventory.length).to eq 1
      expect(entity.inventory[0].first).to eq Item.new
      expect(entity.inventory[0].second).to eq 1
    end

    it "properly adds the same item to the same slot" do
      entity = Entity.new
      entity.add_item(Item.new, 2)
      expect(entity.inventory[0].second).to eq 2

      entity.add_item(Item.new, 4)
      expect(entity.inventory[0].second).to eq 6
      expect(entity.inventory.length).to eq 1
    end

    it "handles multiple items being added in succession" do
      entity = Entity.new
      entity.add_item(Item.new, 3)
      entity.add_item(Item.new(name: "Apple"), 2)
      entity.add_item(Item.new(name: "Orange"), 4)
      entity.add_item(Item.new(name: "Apple"), 3)

      expect(entity.inventory.length).to eq 3

      expect(entity.inventory[0].first).to eq Item.new
      expect(entity.inventory[0].second).to eq 3

      expect(entity.inventory[1].first).to eq Item.new(name: "Apple")
      expect(entity.inventory[1].second).to eq 5

      expect(entity.inventory[2].first).to eq Item.new(name: "Orange")
      expect(entity.inventory[2].second).to eq 4
    end
  end

  context "add rewards" do
    before(:each) do
      @entity = Entity.new
    end

    it "should give the player the appropriate amount of gold" do
      @entity.add_rewards(5, nil)
      expect(@entity.gold).to eq 5
      expect(@entity.inventory.size).to be_zero
    end

    it "should give the player the appropriate treasure item" do
      @entity.add_rewards(0, Item.new)
      expect(@entity.gold).to be_zero
      expect(@entity.inventory).to eq [Couple.new(Item.new, 1)]
    end

    it "should give the player both the gold and the treasure item" do
      @entity.add_rewards(5, Item.new)
      expect(@entity.gold).to eq 5
      expect(@entity.inventory).to eq [Couple.new(Item.new, 1)]
    end

    it "should not output anything for no rewards" do
      expect { @entity.add_rewards(0, nil) }.not_to output.to_stdout
    end

    it "should output both of the rewards" do
      expect { @entity.add_rewards(5, Item.new) }.to output(
        "Rewards:\n* 5 gold\n* Item\n\n"
      ).to_stdout
    end
  end

  context "choose attack" do
    it "randomly selects one of the available commands" do
      kick = BattleCommand.new(name: "Kick")
      zap = BattleCommand.new(name: "Zap")
      entity = Entity.new(battle_commands: [kick, zap])
      attack = entity.choose_attack
      expect(attack.name).to eq("Kick").or(eq("Zap"))
    end
  end

  context "choose item and on whom" do
    it "randomly selects both item and on whom" do
      banana = Item.new(name: "Banana")
      axe = Item.new(name: "Axe")

      entity = Entity.new(inventory: [Couple.new(banana, 1),
                                      Couple.new(axe, 3)])
      enemy = Entity.new(name: "Enemy")

      pair = entity.choose_item_and_on_whom(enemy)
      expect(pair.first.name).to eq("Banana").or(eq("Axe"))
      expect(pair.second.name).to eq("Entity").or(eq("Enemy"))
    end
  end

  context "clear inventory" do
    it "has no effect on an empty inventory" do
      entity = Entity.new
      entity.clear_inventory
      expect(entity.inventory.size).to be_zero
    end

    it "removes all items from a non-empty inventory" do
      entity = Entity.new(inventory: [Couple.new(Item.new, 4),
                                      Couple.new(Item.new(name: "Apple"), 3),
                                      Couple.new(Item.new(name: "Orange"), 7)])
      entity.clear_inventory
      expect(entity.inventory.size).to be_zero
    end
  end

  context "equip item" do
    it "correctly equips the weapon and alters the stats" do
      entity = Entity.new(inventory: [Couple.new(
                                        Weapon.new(stat_change: { attack: 3 },
                                                   attack: Attack.new), 1)])
      entity.equip_item("Weapon")
      expect(entity.outfit[:weapon]).to eq Weapon.new
      expect(entity.attack).to eq 4
      expect(entity.battle_commands).to eq [Attack.new]
    end

    it "correctly equips the helmet and alters the stats" do
      entity = Entity.new(inventory: [Couple.new(
                                        Helmet.new(stat_change: { defense: 3 } ), 1)])
      entity.equip_item("Helmet")
      expect(entity.outfit[:helmet]).to eq Helmet.new
      expect(entity.defense).to eq 4
    end

    it "correctly equips the shield and alters the stats" do
      entity = Entity.new(inventory: [Couple.new(
                                        Shield.new(stat_change: { defense: 3,
                                                                  agility: 2 } ), 1)])
      entity.equip_item("Shield")
      expect(entity.outfit[:shield]).to eq Shield.new
      expect(entity.defense).to eq 4
      expect(entity.agility).to eq 3
    end

    it "correctly equips the legs and alters the stats" do
      entity = Entity.new(inventory: [Couple.new(
                                        Legs.new(stat_change: { defense: 3 } ), 1)])
      entity.equip_item("Legs")
      expect(entity.outfit[:legs]).to eq Legs.new
      expect(entity.defense).to eq 4
    end

    it "correctly equips the torso and alters the stats" do
      entity = Entity.new(inventory: [Couple.new(
                                        Torso.new(stat_change: { defense: 3 } ), 1)])
      entity.equip_item("Torso")
      expect(entity.outfit[:torso]).to eq Torso.new
      expect(entity.defense).to eq 4
    end

    it "does not equip anything for an absent item" do
      entity = Entity.new
      entity.equip_item("Weapon")
      expect(entity.outfit).to be_empty
    end

    it "only removes one of the equipped item from the inventory" do
      entity = Entity.new(inventory: [Couple.new(
                                        Helmet.new(stat_change: { defense: 3 } ), 2)])
      entity.equip_item("Helmet")
      expect(entity.inventory.length).to eq 1
      expect(entity.inventory[0].first).to eq Helmet.new
      expect(entity.inventory[0].second).to eq 1
    end

    it "correctly switches the equipped items and alters status as appropriate" do
      entity = Entity.new(inventory: [Couple.new(
                                        Weapon.new(name: "Hammer",
                                                   stat_change: { attack: 3,
                                                                  defense: 2,
                                                                  agility: 4 },
                                                   attack: Attack.new(name: "Bash")), 1),
                                      Couple.new(
                                        Weapon.new(name: "Knife",
                                                   stat_change: { attack: 5,
                                                                  defense: 3,
                                                                  agility: 7 },
                                                   attack: Attack.new(name: "Stab")), 1)])
      entity.equip_item("Hammer")
      expect(entity.attack).to eq 4
      expect(entity.defense).to eq 3
      expect(entity.agility).to eq 5
      expect(entity.outfit[:weapon].name).to eq "Hammer"
      expect(entity.battle_commands).to eq [Attack.new(name: "Bash")]
      expect(entity.inventory.length).to eq 1
      expect(entity.inventory[0].first.name).to eq "Knife"

      entity.equip_item("Knife")
      expect(entity.attack).to eq 6
      expect(entity.defense).to eq 4
      expect(entity.agility).to eq 8
      expect(entity.outfit[:weapon].name).to eq "Knife"
      expect(entity.battle_commands).to eq [Attack.new(name: "Stab")]
      expect(entity.inventory.length).to eq 1
      expect(entity.inventory[0].first.name).to eq "Hammer"
    end

    it "prints an error message for an unequippable item" do
      entity = Entity.new(inventory: [Couple.new(Item.new, 1)])
      expect { entity.equip_item("Item") }.to output(
        "Item cannot be equipped!\n\n"
      ).to_stdout
    end
  end

  context "has battle command" do
    it "correctly indicates an absent command for an object argument" do
      entity = Entity.new(battle_commands: [
        BattleCommand.new(name: "Kick"),
        BattleCommand.new(name: "Poke")])
      index = entity.has_battle_command(BattleCommand.new(name: "Chop"))
      expect(index).to be_nil
    end

    it "correctly indicates a present command for an object argument" do
      entity = Entity.new(battle_commands: [
        BattleCommand.new(name: "Kick"),
        BattleCommand.new(name: "Poke")])
      index = entity.has_battle_command(BattleCommand.new(name: "Poke"))
      expect(index).to eq 1
    end

    it "correctly indicates an absent command for a string argument" do
      entity = Entity.new(battle_commands: [
        BattleCommand.new(name: "Kick"),
        BattleCommand.new(name: "Poke")])
      index = entity.has_battle_command("Chop")
      expect(index).to be_nil
    end

    it "correctly indicates a present command for a string argument" do
      entity = Entity.new(battle_commands: [
        BattleCommand.new(name: "Kick"),
        BattleCommand.new(name: "Poke")])
      index = entity.has_battle_command("Poke")
      expect(index).to eq 1
    end
  end

  context "has item" do
    it "correctly indicates an absent item for an object argument" do
      entity = Entity.new
      entity.add_item(Item.new(name: "Apple"))
      entity.add_item(Item.new(name: "Orange"))
      index = entity.has_item(Item.new(name: "Banana"))
      expect(index).to be_nil
    end

    it "correctly indicates a present item for an object argument" do
      entity = Entity.new
      entity.add_item(Item.new(name: "Apple"))
      entity.add_item(Item.new(name: "Orange"))
      index = entity.has_item(Item.new(name: "Apple"))
      expect(index).to eq 0
    end

    it "correctly indicates an absent item for a string argument" do
      entity = Entity.new
      entity.add_item(Item.new(name: "Apple"))
      entity.add_item(Item.new(name: "Orange"))
      index = entity.has_item("Banana")
      expect(index).to be_nil
    end

    it "correctly indicates a present item for a string argument" do
      entity = Entity.new
      entity.add_item(Item.new(name: "Apple"))
      entity.add_item(Item.new(name: "Orange"))
      index = entity.has_item("Orange")
      expect(index).to eq 1
    end
  end

  context "print battle commands" do
    it "should print only a newline when there are no battle commands" do
      entity = Entity.new
      expect { entity.print_battle_commands }.to output("\n").to_stdout
    end

    it "should print each battle command in a list" do
      kick = Attack.new(name: "Kick")
      entity = Entity.new(battle_commands: [kick, Use.new, Escape.new])
      expect { entity.print_battle_commands }.to output(
        "❊ Escape\n❊ Kick\n❊ Use\n\n"
      ).to_stdout
    end
  end

  context "print inventory" do
    it "should print the inventory is empty when it is" do
      entity = Entity.new
      expect { entity.print_inventory }.to output(
        "Current gold in pouch: 0.\n\nEntity's inventory is empty!\n\n"
      ).to_stdout
    end

    it "should print the complete inventory when not empty" do
      apple = Item.new(name: "Apple")
      banana = Item.new(name: "Banana")
      entity = Entity.new(gold: 33, inventory: [
        Couple.new(apple, 1), Couple.new(banana, 2)] )
      expect { entity.print_inventory }.to output(
        "Current gold in pouch: 33.\n\nEntity's inventory:\n"\
        "* Apple (1)\n* Banana (2)\n\n"
      ).to_stdout
    end
  end

  context "print status" do
    it "prints all of the entity's information" do
      entity = Entity.new(max_hp: 50, hp: 30, attack: 5,
                          defense: 3, agility: 4,
                          outfit: { helmet: Helmet.new,
                                    legs: Legs.new,
                                    shield: Shield.new,
                                    torso: Torso.new,
                                    weapon: Weapon.new },
                          battle_commands: [Escape.new])
      expect { entity.print_status }.to output(
        "Stats:\n* HP: 30/50\n* Attack: 5\n* Defense: 3\n* Agility: 4\n\n"\
        "Equipment:\n* Weapon: Weapon\n* Shield: Shield\n* Helmet: Helmet\n"\
        "* Torso: Torso\n* Legs: Legs\n\nBattle Commands:\n❊ Escape\n\n"
      ).to_stdout
    end

    it "prints the appropriate info for the default Entity" do
      entity = Entity.new
      expect { entity.print_status }.to output(
      "Stats:\n* HP: 1/1\n* Attack: 1\n* Defense: 1\n* Agility: 1\n\n"\
      "Equipment:\n* Weapon: none\n* Shield: none\n* Helmet: none\n"\
      "* Torso: none\n* Legs: none\n\n"
      ).to_stdout
    end
  end

  context "remove battle command" do
    it "has no effect when no such command is present" do
      entity = Entity.new
      entity.add_battle_command(Attack.new(name: "Kick"))
      entity.remove_battle_command(BattleCommand.new(name: "Poke"))
      expect(entity.battle_commands.length).to eq 1
    end

    it "correctly removes the command in the trivial case" do
      entity = Entity.new
      entity.add_battle_command(Attack.new(name: "Kick"))
      entity.remove_battle_command(Attack.new(name: "Kick"))
      expect(entity.battle_commands.length).to eq 0
    end
  end

  context "remove gold" do
    it "should remove the given amount of gold" do
      entity = Entity.new(gold: 50)
      entity.remove_gold(20)
      expect(entity.gold).to eq 30
    end

    it "should prevent gold < 0" do
      entity = Entity.new(gold: 5)
      entity.remove_gold(10)
      expect(entity.gold).to be_zero
    end
  end

  context "remove item" do
    it "has no effect when no such item is present" do
      entity = Entity.new
      entity.add_item(Item.new(name: "Apple"))
      entity.remove_item(Item.new(name: "Banana"))
      expect(entity.inventory.length).to eq 1
    end

    it "correctly removes the item in the trivial case" do
      entity = Entity.new
      entity.add_item(Item.new(name: "Apple"))
      entity.remove_item(Item.new(name: "Apple"))
      expect(entity.inventory.length).to eq 0
    end

    it "correctly removes multiple of the same item" do
      entity = Entity.new
      entity.add_item(Item.new(name: "Apple"), 4)
      entity.remove_item(Item.new(name: "Apple"), 3)
      expect(entity.inventory.length).to eq 1
      expect(entity.inventory[0].first.name).to eq "Apple"
    end

    it "removes all of an item and leaves no gaps" do
      entity = Entity.new
      entity.add_item(Item.new(name: "Apple"), 4)
      entity.add_item(Item.new(name: "Banana"), 3)
      entity.add_item(Item.new(name: "Orange"), 7)
      entity.remove_item(Item.new(name: "Banana"), 6)

      expect(entity.inventory.length).to eq 2
      expect(entity.inventory[0].first.name).to eq "Apple"
      expect(entity.inventory[1].first.name).to eq "Orange"
    end
  end

  context "set gold" do
    it "should set the gold to the given amount" do
      entity = Entity.new(gold: 10)
      entity.set_gold(15)
      expect(entity.gold).to eq 15
    end

    it "should prevent gold < 0" do
      entity = Entity.new(gold: 5)
      entity.set_gold(-10)
      expect(entity.gold).to be_zero
    end
  end

  context "unequip item" do
    it "correctly unequips an equipped item" do
      entity = Entity.new(outfit: { weapon: Weapon.new(stat_change: {agility: 4},
                                                       attack: Attack.new) })
      entity.unequip_item("Weapon")
      expect(entity.outfit).to be_empty
      expect(entity.inventory.length).to eq 1
      expect(entity.inventory[0].first).to eq Weapon.new
      expect(entity.inventory[0].second).to eq 1
      expect(entity.battle_commands).to be_empty
      expect(entity.agility).to eq 1
    end

    it "does not result in error when unequipping the same item twice" do
      entity = Entity.new(inventory: [Couple.new(
                                        Helmet.new(stat_change: { defense: 3 } ), 2)])
      entity.equip_item("Helmet")
      entity.unequip_item("Helmet")
      expect(entity.inventory.length).to eq 1
      expect(entity.inventory[0].first).to eq Helmet.new
      expect(entity.inventory[0].second).to eq 2

      entity.unequip_item("Helmet")
      expect(entity.inventory.length).to eq 1
      expect(entity.inventory[0].first).to eq Helmet.new
      expect(entity.inventory[0].second).to eq 2
    end
  end

  context "use item" do
    it "correctly uses a present item for an object argument" do
      entity = Entity.new(max_hp: 20, hp: 10,
                          inventory: [Couple.new(Food.new(recovers: 5), 3)])
      entity.use_item(Food.new, entity)
      expect(entity.hp).to eq 15
      expect(entity.inventory[0].first).to eq Food.new
      expect(entity.inventory[0].second).to eq 2
    end

    it "correctly uses a present item for a string argument" do
      entity = Entity.new(max_hp: 20, hp: 10,
                          inventory: [Couple.new(Food.new(recovers: 5), 3)])
      entity.use_item("Food", entity)
      expect(entity.hp).to eq 15
      expect(entity.inventory[0].first).to eq Food.new
      expect(entity.inventory[0].second).to eq 2
    end
  end

  context "equality operator" do
    it "returns true for the trivial case" do
      entity1 = Entity.new
      entity2 = Entity.new
      expect(entity1).to eq entity2
    end

    it "returns false for Entities with different names" do
      bob = Entity.new(name: "Bob")
      marge = Entity.new(name: "Marge")
      expect(bob).not_to eq marge
    end
  end

end
