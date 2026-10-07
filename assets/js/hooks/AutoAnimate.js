import autoAnimate, { getTransitionSizes } from "@formkit/auto-animate"

const animationDuration = 180
const fadeDuration = 120

const subtleAnimation = (element, action, oldCoordinates, newCoordinates) => {
  if (action === "remove") {
    return new KeyframeEffect(
      element,
      [{ opacity: 0 }, { opacity: 0 }],
      { duration: fadeDuration },
    )
  }

  if (action === "add") {
    return new KeyframeEffect(
      element,
      [{ opacity: 0 }, { opacity: 1 }],
      {
        duration: fadeDuration,
        easing: "ease-out",
      },
    )
  }

  let deltaLeft = oldCoordinates.left - newCoordinates.left
  let deltaTop = oldCoordinates.top - newCoordinates.top
  const deltaRight = oldCoordinates.left + oldCoordinates.width
    - (newCoordinates.left + newCoordinates.width)
  const deltaBottom = oldCoordinates.top + oldCoordinates.height
    - (newCoordinates.top + newCoordinates.height)

  if (deltaBottom === 0) deltaTop = 0
  if (deltaRight === 0) deltaLeft = 0

  const [widthFrom, widthTo, heightFrom, heightTo] = getTransitionSizes(
    element,
    oldCoordinates,
    newCoordinates,
  )
  const start = { transform: `translate(${deltaLeft}px, ${deltaTop}px)` }
  const end = { transform: "translate(0, 0)" }

  if (widthFrom !== widthTo) {
    start.width = `${widthFrom}px`
    end.width = `${widthTo}px`
  }

  if (heightFrom !== heightTo) {
    start.height = `${heightFrom}px`
    end.height = `${heightTo}px`
  }

  return new KeyframeEffect(element, [start, end], {
    duration: animationDuration,
    easing: "ease-in-out",
  })
}

export const AutoAnimate = {
  mounted() {
    this.animation = autoAnimate(this.el, subtleAnimation)
  },

  destroyed() {
    this.animation.disable()
  },
}
