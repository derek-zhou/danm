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

  # this is for the void elements that should not have inner text
  defp element(s, tag, attrs) do
    ["<#{tag}#{attr_string(attrs)}>\n" | s]
  end

  # this is for the non-void elements that may have inner text
  defp element(s, tag, text, attrs) when is_binary(text) do
    start_tag = "<#{tag}#{attr_string(attrs)}>"
    end_tag = "</#{tag}>\n"
    [ end_tag | text([start_tag | s], text)]
  end

  defp element(s, tag, func, attrs) when is_function(func, 1) do
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
      v -> " #{key}=\"#{v}\""
    end
  end

  @doc ~S"""
  Just add some text
  """
  # TODO: html escape text
  def text(s, text) when is_binary(text), do: [ text | s]

  def html(s, inner, attrs \\ []), do: element(s, "html", inner, attrs)
  def head(s, inner, attrs \\ []), do: element(s, "head", inner, attrs)
  def body(s, inner, attrs \\ []), do: element(s, "body", inner, attrs)

  def meta(s, attrs \\ []), do: element(s, "meta", attrs)
  def link(s, attrs \\ []), do: element(s, "link", attrs)

  def hr(s, attrs \\ []), do: element(s, "hr", attrs)
  def br(s, attrs \\ []), do: element(s, "br", attrs)
  def img(s, attrs \\ []), do: element(s, "img", attrs)

  def title(s, inner, attrs \\ []), do: element(s, "title", inner, attrs)
  def style(s, inner, attrs \\ []), do: element(s, "style", inner, attrs)
  def voild_script(s, attrs \\ []), do: element(s, "script", "", attrs)
  def script(s, inner, attrs \\ []), do: element(s, "script", inner, attrs)

  def h1(s, inner, attrs \\ []), do: element(s, "h1", inner, attrs)
  def h2(s, inner, attrs \\ []), do: element(s, "h2", inner, attrs)
  def h3(s, inner, attrs \\ []), do: element(s, "h3", inner, attrs)
  def h4(s, inner, attrs \\ []), do: element(s, "h4", inner, attrs)
  def h5(s, inner, attrs \\ []), do: element(s, "h5", inner, attrs)
  def h6(s, inner, attrs \\ []), do: element(s, "h6", inner, attrs)

  def p(s, inner, attrs \\ []), do: element(s, "p", inner, attrs)
  def a(s, inner, attrs \\ []), do: element(s, "a", inner, attrs)
  def div(s, inner, attrs \\ []), do: element(s, "div", inner, attrs)
  def ul(s, inner, attrs \\ []), do: element(s, "ul", inner, attrs)
  def li(s, inner, attrs \\ []), do: element(s, "li", inner, attrs)

  def table(s, inner, attrs \\ []), do: element(s, "table", inner, attrs)
  def tr(s, inner, attrs \\ []), do: element(s, "tr", inner, attrs)
  def th(s, inner, attrs \\ []), do: element(s, "th", inner, attrs)
  def td(s, inner, attrs \\ []), do: element(s, "td", inner, attrs)

end
