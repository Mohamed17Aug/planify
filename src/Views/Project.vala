/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class Views.Project : Gtk.EventBox {
    public Objects.Project project { get; set; }

    private Gtk.Label name_label;
    private Widgets.Entry name_entry;
    private Gtk.Revealer action_revealer;
    private Widgets.TextView note_textview;
    private Gtk.Stack note_stack;
    private Gtk.Label note_label;
    private Gtk.Stack name_stack;

    private Gtk.ModelButton show_completed_button;
    private Gtk.Switch show_completed_switch;
    private Gtk.Switch board_switch;
    private Gtk.ModelButton board_button;
    private Gtk.Stack main_stack;
    private Widgets.BoardView board_view = null;
    private Widgets.ListView list_view = null;
    private Gtk.Label progress_label;
    private Gtk.LevelBar progress_bar;
    private Gtk.LevelBar due_bar;
    private Widgets.Entry section_name_entry;
    private Gtk.ToggleButton section_button;
    private Gtk.Popover new_section_popover = null;
    private Gtk.Popover popover = null;
    private Gtk.Menu share_menu = null;
    private Gtk.ToggleButton settings_button;

    private Gtk.Popover progress_popover = null;
    private Gtk.ToggleButton deadline_button;
    
    private Gtk.Revealer deadline_revealer;
    private Gtk.Label deadline_label;

    private int64 temp_id_mapping { get; set; default = 0; }
    private bool entry_menu_opened = false;

    construct {
        var color_popover = new Widgets.ColorPopover ();

        var project_progress = new Widgets.ProjectProgress (16);
        project_progress.valign = Gtk.Align.CENTER;
        project_progress.halign = Gtk.Align.CENTER;

        var progress_button = new Gtk.MenuButton ();
        progress_button.valign = Gtk.Align.START;
        progress_button.get_style_context ().add_class ("no-padding");
        progress_button.get_style_context ().add_class ("flat");
        progress_button.add (project_progress);
        progress_button.popover = color_popover;
        progress_button.margin_end = 12;
        progress_button.margin_top = 2;

        name_label = new Gtk.Label (null);
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("title-label");
        name_label.get_style_context ().add_class ("font-bold");

        var source_icon = new Gtk.Image ();
        source_icon.pixel_size = 16;

        var name_eventbox = new Gtk.EventBox ();
        name_eventbox.valign = Gtk.Align.START;
        name_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        name_eventbox.hexpand = true;
        name_eventbox.add (name_label);

        name_entry = new Widgets.Entry ();
        name_entry.get_style_context ().add_class ("font-bold");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("title-label");
        name_entry.get_style_context ().add_class ("project-name-entry");
        name_entry.hexpand = true;

        name_stack = new Gtk.Stack ();
        name_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        name_stack.add_named (name_eventbox, "name_label");
        name_stack.add_named (name_entry, "name_entry");

        var deadline_icon = new Gtk.Image ();
        deadline_icon.gicon = new ThemedIcon ("edit-flag-symbolic");
        deadline_icon.pixel_size = 14;

        deadline_label = new Gtk.Label (null);
        deadline_label.get_style_context ().add_class ("font-bold");

        var deadline_grid = new Gtk.Grid ();
        deadline_grid.add (deadline_icon);
        deadline_grid.add (deadline_label);

        deadline_button = new Gtk.ToggleButton ();
        deadline_button.halign = Gtk.Align.CENTER;
        deadline_button.can_focus = false;
        deadline_button.get_style_context ().add_class ("flat");
        deadline_button.add (deadline_grid);

        deadline_revealer = new Gtk.Revealer ();
        deadline_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        deadline_revealer.add (deadline_button);

        var section_image = new Gtk.Image ();
        section_image.gicon = new ThemedIcon ("section-symbolic");
        section_image.pixel_size = 16;

        section_button = new Gtk.ToggleButton ();
        section_button.valign = Gtk.Align.CENTER;
        section_button.halign = Gtk.Align.CENTER;
        section_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl><Shift>S"}, _("Add Section"));
        section_button.can_focus = false;
        section_button.get_style_context ().add_class ("flat");
        section_button.add (section_image);

        var settings_image = new Gtk.Image ();
        settings_image.gicon = new ThemedIcon ("view-more-symbolic");
        settings_image.pixel_size = 16;

        settings_button = new Gtk.ToggleButton ();
        settings_button.valign = Gtk.Align.START;
        settings_button.can_focus = false;
        settings_button.tooltip_text = _("Project Menu");
        settings_button.image = settings_image;
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var label_filter = new Widgets.LabelFilter ();
        var sort_button = new Widgets.SortButton ();

        var submit_button = new Gtk.Button.with_label (_("Save"));
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("planner-button");

        var action_grid = new Gtk.Grid ();
        action_grid.halign = Gtk.Align.START;
        action_grid.margin_top = 6;
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.margin_start = 65;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        action_revealer = new Gtk.Revealer ();
        action_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        action_revealer.add (action_grid);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_end = 32;
        top_box.margin_start = 42;
        top_box.margin_top = 6;
        top_box.pack_start (progress_button, false, false, 0);
        top_box.pack_start (name_stack, false, true, 0);
        top_box.pack_end (settings_button, false, false, 0);
        top_box.pack_end (sort_button, false, false, 0);
        top_box.pack_end (label_filter, false, false, 0);
        top_box.pack_end (deadline_revealer, false, false, 0);

        note_textview = new Widgets.TextView ();
        note_textview.tooltip_text = _("Add a description");
        note_textview.hexpand = true;
        // note_textview.valign = Gtk.Align.START;
        note_textview.wrap_mode = Gtk.WrapMode.CHAR;
        note_textview.get_style_context ().add_class ("project-textview");

        // Note Label
        note_label = new Gtk.Label ("");
        note_label.wrap = true;
        note_label.wrap_mode = Pango.WrapMode.CHAR;
        note_label.xalign = 0;
        note_label.yalign = 0;
        note_label.hexpand = true;
        note_label.use_markup = true;

        var note_eventbox = new Gtk.EventBox ();
        note_eventbox.hexpand = true;
        note_eventbox.add (note_label);

        note_stack = new Gtk.Stack ();
        note_stack.hexpand = true;
        note_stack.margin_top = 12;
        note_stack.margin_start = 42;
        note_stack.margin_end = 43;
        note_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        note_stack.vhomogeneous = false;
        note_stack.add_named (note_eventbox, "label");
        note_stack.add_named (note_textview, "textview");
        
        var placeholder_view = new Widgets.Placeholder (
            _("What will you accomplish?"),
            _("Tap + to add a task to this project."),
            "planner-project-symbolic"
        );
        placeholder_view.reveal_child = true;

        main_stack = new Gtk.Stack ();
        main_stack.expand = true;
        main_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        list_view = new Widgets.ListView ();
        board_view = new Widgets.BoardView ();

        main_stack.add_named (placeholder_view, "placeholder");
        main_stack.add_named (board_view, "board");
        main_stack.add_named (list_view, "project");

        var magic_button = new Widgets.MagicButton ();

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (action_revealer, false, false, 0);
        main_box.pack_start (note_stack, false, false, 0);
        main_box.pack_start (main_stack, false, true, 0);

        var overlay = new Gtk.Overlay ();
        overlay.expand = true;
        overlay.add_overlay (magic_button);
        overlay.add (main_box);
        
        add (overlay);

        notify["project"].connect (() => {
            name_label.label = project.name;
            name_entry.text = project.name;
            note_textview.buffer.text = project.note;
            update_note_label (project.note);

            if (project.is_todoist == 0) {
                source_icon.gicon = new ThemedIcon ("planner-offline-symbolic");
                source_icon.tooltip_text = _("Local Project");
            } else {
                source_icon.gicon = new ThemedIcon ("planner-online-symbolic");
                source_icon.tooltip_text = _("Todoist Project");
            }

            label_filter.project = project;
            sort_button.project = project;
            deadline_button.tooltip_text = _("Progress: %s".printf (GLib.Math.round ((project_progress.percentage * 100)).to_string ())) + "%";
            project_progress.progress_fill_color = Planner.utils.get_color (project.color);
            color_popover.selected = project.color;
            project_progress.percentage = get_percentage (
                Planner.database.get_count_checked_items_by_project (project.id),
                Planner.database.get_all_count_items_by_project (project.id)
            );

            check_due_date ();
            
            list_view.project = project;
            board_view.project = project;

            if (project.is_kanban == 1) {
                board_view.add_boards ();
            } else {
                list_view.add_sections ();
            }

            show_all ();

            Timeout.add (main_stack.transition_duration, () => {
                Planner.database.get_project_count (project.id);
                
                if (project.is_kanban == 1) {
                    main_stack.visible_child_name = "board";
                } else {
                    main_stack.visible_child_name = "project";
                }
                
                return GLib.Source.REMOVE;
            });
        });

        color_popover.color_changed.connect ((color) => {
            if (project != null) {
                project.color = color;
                save (true);
            }
        });

        magic_button.clicked.connect (() => {
            if (project.is_kanban == 1) {
                board_view.add_new_item (Planner.settings.get_enum ("new-tasks-position"));
            } else {
                list_view.add_new_item (Planner.settings.get_enum ("new-tasks-position"));
            }
        });

        submit_button.clicked.connect (() => {
            save (true);
        });

        cancel_button.clicked.connect (() => {
            action_revealer.reveal_child = false;
            name_stack.visible_child_name = "name_label";
            name_entry.text = project.name;
        });

        name_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                action_revealer.reveal_child = true;
                name_stack.visible_child_name = "name_entry";

                name_entry.grab_focus_without_selecting ();
                if (name_entry.cursor_position < name_entry.text_length) {
                    name_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) name_entry.text_length, false);
                }
            }

            return false;
        });

        name_entry.activate.connect (() => {
            save (true);
        });

        name_entry.changed.connect (() => {
            if (name_entry.text.strip () != "" && project.name != name_entry.text) {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                action_revealer.reveal_child = false;
                name_stack.visible_child_name = "name_label";
                name_entry.text = project.name;
            }

            return false;
        });

        name_entry.focus_out_event.connect (() => {
            if (entry_menu_opened == false) {
                save (true);
            }
        });

        name_entry.populate_popup.connect ((menu) => {
            entry_menu_opened = true;
            menu.hide.connect (() => {
                entry_menu_opened = false;
            });
        });

        settings_button.toggled.connect (() => {
            Planner.event_bus.unselect_all ();

            if (settings_button.active) {
                if (popover == null) {
                    create_popover ();
                }

                show_completed_switch.active = project.show_completed == 1;
                board_switch.active = project.is_kanban == 1;

                popover.show_all ();
            }
        });

        note_textview.focus_out_event.connect (() => {
            note_stack.visible_child_name = "label";
            update_note_label (note_textview.buffer.text);

            save (false);
            return false;
        }); 

        note_textview.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                note_stack.visible_child_name = "label";
                update_note_label (note_textview.buffer.text);
            }

            return false;
        });

        note_eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS) {
                note_stack.visible_child_name = "textview";
                note_textview.grab_focus ();

                return true;
            }

            return false;
        });

        section_button.toggled.connect (() => {
            Planner.event_bus.unselect_all ();
            open_new_section ();
        });

        deadline_button.toggled.connect (() => {
            Planner.event_bus.unselect_all ();
            open_progress_popover ();
        });

        Planner.database.project_updated.connect ((p) => {
            if (project != null && p.id == project.id) {
                project = p;

                name_label.label = p.name;
                name_entry.text = p.name;
                note_textview.buffer.text = p.note;
                project_progress.progress_fill_color = Planner.utils.get_color (p.color);

                update_note_label (note_textview.buffer.text);
                check_due_date ();
            }
        });

        Planner.database.project_id_updated.connect ((current_id, new_id) => {
            Idle.add (() => {
                if (project.id == current_id) {
                    project.id = new_id;
                }

                return false;
            });
        });

        Planner.database.check_project_count.connect ((id) => {
            if (project.id == id) {
                project_progress.percentage = get_percentage (
                    Planner.database.get_count_checked_items_by_project (project.id),
                    Planner.database.get_all_count_items_by_project (project.id)
                );
                deadline_button.tooltip_text = _("Progress: %s".printf (GLib.Math.round ((project_progress.percentage * 100)).to_string ())) + "%";
            }
        });

        Planner.event_bus.edit_project.connect ((id) => {
            if (project.id == id) {
                edit ();
            }
        });
    }

    public void edit () {
        action_revealer.reveal_child = true;
        name_stack.visible_child_name = "name_entry";
        name_entry.grab_focus ();
    }

    private void update_note_label (string text) {
        if (text.strip () == "") {
            note_label.label = _("Description");
            note_label.opacity = 0.7;
        } else {
            note_label.label = Planner.utils.get_markup_format (text);
            note_label.opacity = 1.0;
        }
    }

    private double get_percentage (int a, int b) {
        return (double) a / (double) b;
    }
    
    private void save (bool todoist=true) {
        if (project != null) {
            project.note = note_textview.buffer.text;
            project.name = name_entry.text;

            name_label.label = name_entry.text;
            action_revealer.reveal_child = false;
            name_stack.visible_child_name = "name_label";

            project.save (todoist);
        }
    }

    private void create_popover () {
        popover = new Gtk.Popover (settings_button);
        popover.get_style_context ().add_class ("popover-background");
        popover.position = Gtk.PositionType.BOTTOM;

        var open_menu = new Widgets.ModelButton (_("Open New Window"), "window-new-symbolic", "");
        var edit_menu = new Widgets.ModelButton (_("Edit Project"), "edit-symbolic", "");
        var sort_date_menu = new Widgets.ModelButton (_("Sort by date"), "x-office-calendar-symbolic", "");
        var sort_priority_menu = new Widgets.ModelButton (_("Sort by priority"), "edit-flag-symbolic", "");
        var sort_name_menu = new Widgets.ModelButton (_("Sort by name"), "font-x-generic-symbolic", "");
        //var archive_menu = new Widgets.ModelButton (_("Archive project"), "planner-archive-symbolic");
        var utilities_item = new Widgets.ModelButton (_("Utilities"), "applications-utilities-symbolic", "", true);
        var order_by_item = new Widgets.ModelButton (_("Utilities"), "applications-utilities-symbolic", "", true);

        var delete_menu = new Widgets.ModelButton (_("Delete"), "user-trash-symbolic");
        delete_menu.get_style_context ().add_class ("menu-danger");

        // Show Complete
        var show_completed_image = new Gtk.Image ();
        show_completed_image.gicon = new ThemedIcon ("emblem-default-symbolic");
        show_completed_image.valign = Gtk.Align.START;
        show_completed_image.pixel_size = 16;

        var show_completed_label = new Gtk.Label (_("Show Completed"));
        show_completed_label.hexpand = true;
        show_completed_label.valign = Gtk.Align.START;
        show_completed_label.xalign = 0;
        show_completed_label.margin_start = 9;

        show_completed_switch = new Gtk.Switch ();
        show_completed_switch.margin_start = 12;
        show_completed_switch.get_style_context ().add_class ("planner-switch");

        var show_completed_grid = new Gtk.Grid ();
        show_completed_grid.add (show_completed_image);
        show_completed_grid.add (show_completed_label);
        show_completed_grid.add (show_completed_switch);

        show_completed_button = new Gtk.ModelButton ();
        show_completed_button.get_style_context ().add_class ("popover-model-button");
        show_completed_button.get_child ().destroy ();
        show_completed_button.add (show_completed_grid);

        // Board iew
        var board_image = new Gtk.Image ();
        board_image.gicon = new ThemedIcon ("align-vertical-top-symbolic");
        board_image.valign = Gtk.Align.START;
        board_image.pixel_size = 16;

        var board_label = new Gtk.Label (_("View as board"));
        board_label.hexpand = true;
        board_label.valign = Gtk.Align.START;
        board_label.xalign = 0;
        board_label.margin_start = 9;

        board_switch = new Gtk.Switch ();
        board_switch.margin_start = 12;
        board_switch.get_style_context ().add_class ("planner-switch");

        var board_grid = new Gtk.Grid ();
        board_grid.add (board_image);
        board_grid.add (board_label);
        board_grid.add (board_switch);

        board_button = new Gtk.ModelButton ();
        board_button.get_style_context ().add_class ("popover-model-button");
        board_button.get_child ().destroy ();
        board_button.add (board_grid);

        var popover_grid = new Gtk.Grid ();
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.margin_top = 3;
        popover_grid.margin_bottom = 3;
        popover_grid.add (open_menu);
        popover_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        });
        popover_grid.add (edit_menu);
        popover_grid.add (board_button);
        popover_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        });
        // popover_grid.add (sort_date_menu);
        // popover_grid.add (sort_priority_menu);
        // popover_grid.add (sort_name_menu);
        //  popover_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
        //      margin_top = 3,
        //      margin_bottom = 3
        //  });
        popover_grid.add (utilities_item);
        popover_grid.add (show_completed_button);
        popover_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        });
        popover_grid.add (delete_menu);

        popover.add (popover_grid);

        popover.closed.connect (() => {
            settings_button.active = false;
        });

        edit_menu.clicked.connect (() => {
            var dialog = new Dialogs.ProjectSettings (project);
            dialog.destroy.connect (Gtk.main_quit);
            

            popover.popdown ();
        });

        open_menu.clicked.connect (() => {
            var dialog = new Dialogs.Project (project);
            dialog.destroy.connect (Gtk.main_quit);
            
            int window_x, window_y;
            var rect = Gtk.Allocation ();
            
            Planner.settings.get ("project-dialog-position", "(ii)", out window_x, out window_y);
            Planner.settings.get ("project-dialog-size", "(ii)", out rect.width, out rect.height);

            dialog.set_allocation (rect);
            dialog.move (window_x, window_y);
            dialog.show_all ();

            popover.popdown ();
        });

        delete_menu.clicked.connect (() => {
            popover.popdown ();

            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Delete project"),
                _("Are you sure you want to delete <b>%s</b>?".printf (Planner.utils.get_dialog_text (project.name))),
                "user-trash-full",
            Gtk.ButtonsType.CANCEL);

            var remove_button = new Gtk.Button.with_label (_("Delete"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                Planner.database.delete_project (project.id);
                if (project.is_todoist == 1) {
                    Planner.todoist.delete_project (project);
                }
            }

            message_dialog.destroy ();
        });

        show_completed_button.button_release_event.connect (() => {
            show_completed_switch.activate ();

            if (show_completed_switch.active) {
                project.show_completed = 0;
            } else {
                project.show_completed = 1;
            }

            Planner.database.project_show_completed (project);
            save (false);
            
            return Gdk.EVENT_STOP;
        });

        board_button.button_release_event.connect (() => {
            board_switch.activate ();

            list_view.remove_sections ();
            board_view.remove_boards ();

            if (board_switch.active) {
                project.is_kanban = 0;
                list_view.add_sections ();
                main_stack.visible_child_name = "project";
            } else {
                project.is_kanban = 1;
                board_view.add_boards ();
                main_stack.visible_child_name = "board";
            }
            
            show_all ();
            save (false);
            return Gdk.EVENT_STOP;
        });

        sort_date_menu.clicked.connect (() => {
            Planner.database.update_sort_order_project (project.id, 1);
            popover.popdown ();
        });

        sort_priority_menu.clicked.connect (() => {
            Planner.database.update_sort_order_project (project.id, 2);
            popover.popdown ();
        });

        sort_name_menu.clicked.connect (() => {
            Planner.database.update_sort_order_project (project.id, 3);
            popover.popdown ();
        });

        utilities_item.clicked.connect (() => {
            if (share_menu == null) {
                share_menu = new Gtk.Menu ();

                var share_mail = new Widgets.ImageMenuItem (_("Send by e-mail"), "internet-mail-symbolic");
                var share_markdown_menu = new Widgets.ImageMenuItem (_("Share on Markdown"), "planner-markdown-symbolic");
                var hide_items_menu = new Widgets.ImageMenuItem (_("Hide all tasks details"), "view-restore-symbolic");

                share_menu.add (share_mail);
                share_menu.add (share_markdown_menu);
                share_menu.add (hide_items_menu);
                share_menu.show_all ();

                share_mail.activate.connect (() => {
                    project.share_mail ();
                });
        
                share_markdown_menu.activate.connect (() => {
                    project.share_markdown ();
                });

                hide_items_menu.activate.connect (() => {
                    Planner.event_bus.hide_items_project (project.id);
                    popover.popdown ();
                });
            }

            share_menu.popup_at_pointer (null);
        });
    }

    public void open_new_section () {
        if (new_section_popover == null) {
            build_new_section_popover ();
        }

        new_section_popover.show_all ();
        section_name_entry.grab_focus ();
    }

    public void open_progress_popover () {
        if (progress_popover == null) {
            build_progress_popover ();
        }

        int checked = Planner.database.get_count_checked_items_by_project (project.id);
        int all = Planner.database.get_all_count_items_by_project (project.id);

        progress_bar.value = (double) checked / (double) all;
        progress_label.label = "%i/%i".printf (
            checked,
            all
        );

        // due_bar.value = get_due_progress ();

        progress_popover.show_all ();
    }

    public void build_progress_popover () {
        progress_popover = new Gtk.Popover (deadline_button);
        progress_popover.get_style_context ().add_class ("popover-background");
        progress_popover.position = Gtk.PositionType.BOTTOM;

        var productivity_label = new Gtk.Label ("<small>%s</small>".printf (_("Your Productivity")));
        productivity_label.use_markup = true;
        productivity_label.get_style_context ().add_class ("dim-label");
        productivity_label.get_style_context ().add_class ("font-weight-600");

        var progress_header = new Granite.HeaderLabel (_("Progress:"));
        progress_label = new Gtk.Label (null);
        progress_label.get_style_context ().add_class ("dim-label");

        var progress_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        progress_box.pack_start (progress_header, false, false, 0);
        progress_box.pack_end (progress_label, false, false, 0);

        progress_bar = new Gtk.LevelBar.for_interval (0, 1);
        progress_bar.hexpand = true;

        var due_header = new Granite.HeaderLabel (_("Duedate:"));
        due_header.margin_top = 6;
        due_bar = new Gtk.LevelBar.for_interval (0, 1);
        due_bar.hexpand = true;
        //  var last_7_days = new Granite.HeaderLabel (_("Completed in the last 7 days:"));
        //  last_7_days.margin_top = 6;

        //  var day_01_label = new Gtk.Label ("Tue");

        //  var progress_01_bar = new Gtk.LevelBar.for_interval (0, 1);
        //  progress_01_bar.hexpand = true;
        //  progress_01_bar.valign = Gtk.Align.CENTER;

        //  var progress_01_label = new Gtk.Label ("7");
        //  progress_01_label.get_style_context ().add_class ("dim-label");

        //  var progress_01_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        //  progress_01_box.pack_start (day_01_label, false, false, 0);
        //  progress_01_box.pack_start (progress_01_bar, false, true, 0);
        //  progress_01_box.pack_start (progress_01_label, false, false, 0);

        var popover_grid = new Gtk.Grid ();
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.margin = 12;
        popover_grid.margin_top = 6;
        popover_grid.width_request = 250;
        popover_grid.add (productivity_label);
        popover_grid.add (progress_box);
        popover_grid.add (progress_bar);
        // popover_grid.add (due_header);
        // popover_grid.add (due_bar);

        progress_popover.add (popover_grid);

        progress_popover.closed.connect (() => {
            deadline_button.active = false;
        });
    }

    private void build_new_section_popover () {
        new_section_popover = new Gtk.Popover (section_button);
        new_section_popover.get_style_context ().add_class ("popover-background");
        new_section_popover.position = Gtk.PositionType.BOTTOM;

        var name_label = new Granite.HeaderLabel (_("Name:"));

        section_name_entry = new Widgets.Entry ();
        section_name_entry.hexpand = true;

        var submit_button = new Gtk.Button ();
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var submit_spinner = new Gtk.Spinner ();
        submit_spinner.start ();

        var submit_stack = new Gtk.Stack ();
        submit_stack.expand = true;
        submit_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        submit_stack.add_named (new Gtk.Label (_("Add")), "label");
        submit_stack.add_named (submit_spinner, "spinner");

        submit_button.add (submit_stack);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("planner-button");

        var action_grid = new Gtk.Grid ();
        action_grid.expand = false;
        action_grid.halign = Gtk.Align.START;
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.margin_top = 12;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        var popover_grid = new Gtk.Grid ();
        popover_grid.width_request = 250;
        popover_grid.margin = 6;
        popover_grid.margin_top = 0;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (name_label);
        popover_grid.add (section_name_entry);
        popover_grid.add (action_grid);

        new_section_popover.add (popover_grid);

        new_section_popover.closed.connect (() => {
            section_button.active = false;
        });

        submit_button.clicked.connect (insert_section);

        section_name_entry.activate.connect (() => {
            insert_section ();
        });

        section_name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                section_name_entry.text = "";
                new_section_popover.popdown ();
            }

            return false;
        });

        section_name_entry.changed.connect (() => {
            if (section_name_entry.text != "") {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }
        });

        cancel_button.clicked.connect (() => {
            section_name_entry.text = "";
            new_section_popover.popdown ();
        });

        Planner.todoist.section_added_started.connect ((id) => {
            if (temp_id_mapping == id) {
                submit_stack.visible_child_name = "spinner";
                popover_grid.sensitive = false;
            }
        });

        Planner.todoist.section_added_completed.connect ((id) => {
            if (temp_id_mapping == id) {
                submit_stack.visible_child_name = "label";
                temp_id_mapping = 0;

                popover_grid.sensitive = true;

                section_name_entry.text = "";
                new_section_popover.popdown ();
            }
        });

        Planner.todoist.section_added_error.connect ((id) => {
            if (temp_id_mapping == id) {
                submit_stack.visible_child_name = "label";
                temp_id_mapping = 0;

                popover_grid.sensitive = true;

                section_name_entry.text = "";
                new_section_popover.popdown ();
            }
        });
    }

    private void insert_section () {
        if (section_name_entry.text.strip () != "") {
            var section = new Objects.Section ();
            section.name = section_name_entry.text;
            section.project_id = project.id;
            section.is_todoist = project.is_todoist;

            if (project.is_todoist == 0) {
                section.id = Planner.utils.generate_id ();
                Planner.database.insert_section (section);

                section_name_entry.text = "";
                new_section_popover.popdown ();
            } else {
                var cancellable = new Cancellable ();
                temp_id_mapping = Planner.utils.generate_id ();
                section.is_todoist = 1;

                Planner.todoist.add_section.begin (section, cancellable, temp_id_mapping);
            }
        }
    }

    void check_due_date () {
        if (project.due_date == "") {
            deadline_revealer.reveal_child = false;
        } else {
            deadline_revealer.reveal_child = true;
            var due = new GLib.DateTime.from_iso8601 (project.due_date, new GLib.TimeZone.local ());
            deadline_label.label = Planner.utils.get_relative_date_from_date (due);
        }
    }
}
