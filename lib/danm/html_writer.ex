defmodule Danm.HtmlWriter do
  @moduledoc """
  Provide helper functions to write html programatically into a chardata
  all functions in this module put more data in a chardata
  """

  @doc ~S"""
  helper macro to maintain flow of the pipe operator
  """
  defmacro bind_to(value, name) do
    quote do
      unquote(name) = unquote(value)
    end
  end

  @doc ~S"""
  This is basically Enum.reduce with first 2 argument switched
  """
  def roll_in(s, enum, function), do: Enum.reduce(enum, s, function)

  @doc ~S"""
  Invoke the func with s. This is used to keep the pipe flowing
  """
  def invoke(s, func), do: func.(s)

  @doc ~S"""
  start with minimum boilerplate
  """
  def new_html(), do: ["<!DOCTYPE html>\n"]

  @doc ~S"""
  export the data in the correct order
  """
  def export(s), do: Enum.reverse(s)

  @doc ~S"""
  build a void-element, which is an element that should not have inner text. It may have attributes
  though. Don't call this unless you are making a custom element; use the element specific funcions
  instead.

  tag is the tag name.
  attr are a keyword list of attrbutes, each can be a string, an list of strings, or nil
  """
  def element(s, tag, attrs) do
    ["<#{tag}#{attr_string(attrs)}>\n" | s]
  end

  @doc ~S"""
  build a non-void element, which is an element that may have inner text. It may also have
  attributes. Don't call this unless you are making a custom element; use the element specific
  funcionsinstead.

  tag is the tag name.
  inner can be nil, a string or a function with arity of 1 that build inner text
  attr are a keyword list of attrbutes, each can be a string, an list of strings, or nil
  """
  def element(s, tag, nil, attrs) do
    ["<#{tag}#{attr_string(attrs)}></#{tag}>\n" | s]
  end

  def element(s, tag, text, attrs) when is_binary(text) do
    start_tag = "<#{tag}#{attr_string(attrs)}>"
    end_tag = "</#{tag}>\n"
    [ end_tag | text([start_tag | s], text)]
  end

  def element(s, tag, func, attrs) when is_function(func, 1) do
    start_tag = "<#{tag}#{attr_string(attrs)}>\n"
    end_tag = "</#{tag}>\n"
    inner = [] |> func.() |> Enum.reverse()
    [ end_tag, inner, start_tag ] ++ s
  end

  defp attr_string(attrs) do
    attrs |> Enum.map(&one_attr_string/1) |> Enum.join()
  end

  defp one_attr_string({key, value}) do
    case value do
      nil -> " #{key}"
      list when is_list(list) -> " #{key}=\"#{Enum.join(list, " ")}\""
      v -> " #{key}=\"#{v}\""
    end
  end

  @doc ~S"""
  Just add some text
  """
  def text(s, text) when is_binary(text), do: [ text | s]

  [:meta, :link, :hr, :br, :img]
  |> Enum.each(fn k ->
    str = to_string(k)
    @doc ~s"""
    build void element #{str}
    """
    def unquote(k)(s, attrs \\ []), do: element(s, unquote(str), attrs)
  end)

  [
    :html,
    :head,
    :body,
    :title,
    :style,
    :script,
    :h1,
    :h2,
    :h3,
    :h4,
    :h5,
    :h6,
    :p,
    :a,
    :div,
    :ul,
    :li,
    :table,
    :tr,
    :th,
    :td ]
  |> Enum.each(fn k ->
    str = to_string(k)
    @doc ~s"""
    build non-void element #{str}
    """
    def unquote(k)(s, inner, attrs \\ []), do: element(s, unquote(str), inner, attrs)
  end)

end
