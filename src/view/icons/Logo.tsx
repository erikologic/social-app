import React from 'react'
import {StyleSheet, type TextProps} from 'react-native'
import Svg, {
  Defs,
  G,
  LinearGradient,
  Path,
  type PathProps,
  Rect,
  Stop,
  type SvgProps,
  Use,
} from 'react-native-svg'
import {Image} from 'expo-image'

import {colors} from '#/lib/styles'
import {useKawaiiMode} from '#/state/preferences/kawaii'

const ratio = 57 / 64

type Props = {
  fill?: PathProps['fill']
  style?: TextProps['style']
} & Omit<SvgProps, 'style'>

export const Logo = React.forwardRef(function LogoImpl(props: Props, ref) {
  const {fill, ...rest} = props
  const gradient = fill === 'sky'
  const styles = StyleSheet.flatten(props.style)
  const _fill = gradient ? 'url(#sky)' : fill || styles?.color || colors.blue3
  // @ts-ignore it's fiiiiine
  const size = parseInt(rest.width || 32)

  const isKawaii = useKawaiiMode()

  if (isKawaii) {
    return (
      <Image
        source={
          size > 100
            ? require('../../../assets/kawaii.png')
            : require('../../../assets/kawaii_smol.png')
        }
        accessibilityLabel="Eurosky"
        accessibilityHint=""
        accessibilityIgnoresInvertColors
        style={[{height: size, aspectRatio: 1.4}]}
      />
    )
  }

  return (
    <Svg
      fill="none"
      // @ts-ignore it's fiiiiine
      ref={ref}
      viewBox="0 0 64 57"
      {...rest}
      style={[{width: size, height: size * ratio}, styles]}>
    <Defs>
        <G id="s">
            <G id="c">
                <Path id="t" d="M0,0v1h0.5z" transform="translate(0,-1)rotate(18)" />
                <Use xlinkHref="#t" transform="scale(-1,1)" />
            </G>
            <G id="a">
                <Use xlinkHref="#c" transform="rotate(72)" />
                <Use xlinkHref="#c" transform="rotate(144)" />
            </G>
            <Use xlinkHref="#a" transform="scale(-1,1)" />
        </G>
    </Defs>
    <Rect fill="#039" width="64" height="57" rx="5" />

    <G fill="#fc0" transform="scale(3.8)translate(8.4,8)">
        <Use xlinkHref="#s" y="-6" />
        <Use xlinkHref="#s" y="6" />
        <G id="l">
            <Use xlinkHref="#s" x="-6" />
            <Use xlinkHref="#s" transform="rotate(150)translate(0,6)rotate(66)" />
            <Use xlinkHref="#s" transform="rotate(120)translate(0,6)rotate(24)" />
            <Use xlinkHref="#s" transform="rotate(60)translate(0,6)rotate(12)" />
            <Use xlinkHref="#s" transform="rotate(30)translate(0,6)rotate(42)" />
        </G>
        <Use xlinkHref="#l" transform="scale(-1,1)" />
    </G>
    <Path fill="#1285fe" transform="scale(0.95)translate(2.5,2.5)"    d="M13.873 3.805C21.21 9.332 29.103 20.537 32 26.55v15.882c0-.338-.13.044-.41.867-1.512 4.456-7.418 21.847-20.923 7.944-7.111-7.32-3.819-14.64 9.125-16.85-7.405 1.264-15.73-.825-18.014-9.015C1.12 23.022 0 8.51 0 6.55 0-3.268 8.579-.182 13.873 3.805ZM50.127 3.805C42.79 9.332 34.897 20.537 32 26.55v15.882c0-.338.13.044.41.867 1.512 4.456 7.418 21.847 20.923 7.944 7.111-7.32 3.819-14.64-9.125-16.85 7.405 1.264 15.73-.825 18.014-9.015C62.88 23.022 64 8.51 64 6.55c0-9.818-8.578-6.732-13.873-2.745Z" />

</Svg>

  )
})
