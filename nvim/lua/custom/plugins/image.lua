-- Inline image previews while browsing files.
--
-- neo-tree's `P` (toggle_preview) is already configured with
-- `use_image_nvim = true` (see kickstart/plugins/neo-tree.lua), but the
-- engine it relies on was never installed. This adds it.
--
-- Rendering path: Ghostty (Kitty graphics protocol) -> tmux
-- (`allow-passthrough on`, set in tmux/tmux.conf) -> image.nvim.
--
-- Usage: open the tree (`\` or `nvim .`), put the cursor on an image and
-- press `P`. Preview mode follows the cursor, so moving j/k previews each
-- file -- i.e. "hover to see the image". Press `P` again or `<Esc>` to close.
return {
  '3rd/image.nvim',
  ft = { 'png', 'jpg', 'jpeg', 'gif', 'webp', 'avif' },
  -- Also load eagerly enough that neo-tree's preview can find it on demand.
  lazy = false,
  opts = {
    -- Use the ImageMagick CLI (`convert`, already on the system) rather than
    -- the `magick` luarock, so there's no luarocks build or extra system
    -- package -- keeps the dotfiles reproducible / air-gap-friendly.
    processor = 'magick_cli',
    backend = 'kitty', -- Ghostty speaks the Kitty graphics protocol

    integrations = {
      -- We only want file-browser previews, not inline rendering inside
      -- markdown/neorg buffers (that would pop images mid-edit).
      markdown = { enabled = false },
      neorg = { enabled = false },
    },

    max_width = 100,
    max_height = 30,

    -- Clean up images when they'd be obscured (floats, popups) or when the
    -- tmux window isn't active -- avoids "ghost" images lingering on screen.
    window_overlap_clear_enabled = true,
    tmux_show_only_in_active_window = true,
  },
}
