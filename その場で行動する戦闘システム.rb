=begin
  その場で行動する戦闘システム ver1.0
  byうなぎおおとろ(Twitter http://twitter.com/unagiootoro8388)

  自分のターンが来た時にコマンドを入力できるようにするスクリプトです。

  [使用方法]
  このスクリプトは、導入するだけで使用できます。
=end

module BattleManager
  class << self
    attr_accessor :actor_command_selected
    attr_accessor :phase

    alias battle_system__init_members init_members
    def init_members
      battle_system__init_members
      @actor_command_selected = false
    end

    def set_actor(actor)
      @actor_index = $game_party.members.index(actor)
    end
  end
end

class Scene_Battle
  def prior_command
    start_actor_command_selection
  end

  def command_fight
    turn_start
  end

  def next_command
    BattleManager.actor_command_selected = true
    turn_resume
  end

  def turn_resume
    @party_command_window.close
    @actor_command_window.close
    @status_window.unselect
    @log_window.wait
    @log_window.clear
  end

  def process_action
    return if scene_changing?
    if !@subject || !@subject.current_action
      @subject = BattleManager.next_subject
    end
    return turn_end unless @subject
    if @subject.current_action
      @subject.current_action.prepare
      actor_command_selection if @subject.is_a?(Game_Actor)
      if @subject.current_action.valid?
        @status_window.open
        execute_action
      end
      @subject.remove_current_action
    end
    process_action_end unless @subject.current_action
  end

  def actor_command_selection
    BattleManager.phase = :input
    BattleManager.actor_command_selected = false
    BattleManager.set_actor(@subject)
    start_actor_command_selection
    wait_for_actor_command_selection
    BattleManager.phase = :turn
  end

  def wait_for_actor_command_selection
    abs_wait(1) until BattleManager.actor_command_selected
  end
end
