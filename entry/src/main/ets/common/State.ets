export type Initial = {
  _tag: 'Initial'
}

export type Loading = {
  _tag: 'Loading'
}

export type Content<T> = {
  _tag: 'Content'
  value: T
}

export type Error = {
  _tag: 'Error',
  err: Error
}

export type ViewState<T> = Initial | Loading | Content<T> | Error

export const ViewState = {
  initial: {_tag: 'Initial'} as Initial,
  loading: {_tag: 'Loading'} as Loading,
  empty: () => ({_tag: 'Content', value: undefined}) as Content<void>,
  content: <T>(v: T) => ({_tag: 'Content', value: v}) as Content<T>,
  error: (e: Error) => ({_tag: 'Error', err: e}) as Error,

  isInitial: <T>(view: ViewState<T>): view is Initial => view._tag === 'Initial',
  isLoading: <T>(view: ViewState<T>): view is Loading => view._tag === 'Loading',
  isContent: <T>(view: ViewState<T>): view is Content<T> => view._tag === 'Content',
  isError: <T>(view: ViewState<T>): view is Error => view._tag === 'Error',

  ignoreContent: (view: ViewState<any>) => ({...view, value: undefined}) as ViewState<void>,
}